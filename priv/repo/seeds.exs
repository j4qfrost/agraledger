alias Agraledger.{Repo, Accounts}
alias Agraledger.Accounts.User
alias Agraledger.Directory.{Vendor, Contact}
alias Agraledger.Catalog.Product
alias Agraledger.SupplyChain.SupplyLink
alias Agraledger.Ledger.{Account, JournalEntry}

# --- Admin user (idempotent) -----------------------------------------------
admin_email = "admin@local"
admin_password = "ChangeMe-Pls-12345"

admin =
  case Repo.get_by(User, email: admin_email) do
    nil ->
      {:ok, u} = Accounts.register_user(%{email: admin_email})
      u

    u ->
      u
  end
  |> User.password_changeset(%{password: admin_password}, hash_password: true)
  |> Ecto.Changeset.change(%{
    role: :admin,
    name: "Admin",
    confirmed_at: DateTime.utc_now(:second)
  })
  |> Repo.update!()

IO.puts("Admin: #{admin.email} / #{admin_password}")

# --- Chart of accounts -----------------------------------------------------
coa = [
  # Assets
  {"1000", "Cash", :asset},
  {"1100", "Accounts Receivable", :asset},
  {"1200", "Inventory — Crops", :asset},
  {"1300", "Inventory — Livestock", :asset},
  {"1500", "Equipment", :asset},
  # Liabilities
  {"2000", "Accounts Payable", :liability},
  {"2100", "Operating Loans", :liability},
  # Equity
  {"3000", "Owner's Equity", :equity},
  {"3100", "Retained Earnings", :equity},
  # Revenue
  {"4100", "Crop Sales", :revenue},
  {"4200", "Livestock Sales", :revenue},
  {"4300", "Government Subsidies", :revenue},
  # Expenses
  {"5100", "Seed & Feed", :expense},
  {"5200", "Fertilizer & Chemicals", :expense},
  {"5300", "Fuel", :expense},
  {"5400", "Equipment Repairs", :expense},
  {"5500", "Labor", :expense},
  {"5600", "Logistics & Freight", :expense},
  {"5700", "Utilities", :expense}
]

Enum.each(coa, fn {code, name, type} ->
  case Repo.get_by(Account, code: code) do
    nil ->
      Repo.insert!(%Account{code: code, name: name, type: type, is_postable: true})

    _ ->
      :ok
  end
end)

IO.puts("Seeded #{length(coa)} accounts")

# --- Sample vendors --------------------------------------------------------
sample_vendors = [
  {%{
     name: "Acme Seed Co",
     slug: "acme-seed",
     kind: :supplier,
     website: "https://acme-seed.example",
     notes: "Primary seed supplier — net-30."
   },
   [
     %{name: "Jane Doe", role: "Sales", email: "jane@acme-seed.example", is_primary: true}
   ]},
  {%{
     name: "GreenFields Fertilizer",
     slug: "greenfields",
     kind: :supplier,
     website: "https://greenfields.example",
     notes: "Bulk fertilizer."
   },
   [
     %{name: "Sam Park", role: "Account Manager", email: "sam@greenfields.example", is_primary: true}
   ]},
  {%{
     name: "Northridge Co-op",
     slug: "northridge",
     kind: :customer,
     website: "https://northridge.example",
     notes: "Buys our wheat at harvest."
   },
   [
     %{name: "Rita Singh", role: "Buyer", email: "rita@northridge.example", is_primary: true}
   ]},
  {%{
     name: "QuickHaul Logistics",
     slug: "quickhaul",
     kind: :both,
     website: "https://quickhaul.example",
     notes: "Truck/rail logistics."
   },
   [
     %{name: "Marc Diaz", role: "Dispatcher", email: "marc@quickhaul.example", is_primary: true}
   ]}
]

vendors_by_slug =
  for {attrs, contacts} <- sample_vendors, into: %{} do
    vendor =
      case Repo.get_by(Vendor, slug: attrs.slug) do
        nil -> Repo.insert!(%Vendor{} |> Vendor.changeset(attrs) |> Map.get(:changes) |> then(&struct(Vendor, &1)))
        v -> v
      end

    Enum.each(contacts, fn c ->
      unless Repo.get_by(Contact, email: c.email) do
        %Contact{vendor_id: vendor.id}
        |> Contact.changeset(c)
        |> Repo.insert!()
      end
    end)

    {attrs.slug, vendor}
  end

IO.puts("Seeded #{map_size(vendors_by_slug)} vendors")

# --- Sample products -------------------------------------------------------
sample_products = [
  %{name: "Corn Seed (50lb bag)", sku: "CORN-50", category: :seed, unit: :each, default_price: Money.new(:USD, "120.00")},
  %{name: "Urea Fertilizer (ton)", sku: "UREA-TON", category: :other, unit: :ton, default_price: Money.new(:USD, "650.00")},
  %{name: "Wheat (bushel)", sku: "WHEAT-BU", category: :produce, unit: :bushel, default_price: Money.new(:USD, "7.25")},
  %{name: "Truck transport (mile)", sku: "TRUCK-MI", category: :service, unit: :each, default_price: Money.new(:USD, "3.50")}
]

products_by_sku =
  for attrs <- sample_products, into: %{} do
    product =
      case Repo.get_by(Product, sku: attrs.sku) do
        nil -> %Product{} |> Product.changeset(attrs) |> Repo.insert!()
        p -> p
      end

    {attrs.sku, product}
  end

IO.puts("Seeded #{map_size(products_by_sku)} products")

# --- Sample supply links ---------------------------------------------------
sample_links = [
  # Acme supplies corn seed to us
  %{from_vendor: "acme-seed", to_vendor: nil, product: "CORN-50", role: :upstream},
  # GreenFields supplies fertilizer to us
  %{from_vendor: "greenfields", to_vendor: nil, product: "UREA-TON", role: :upstream},
  # We sell wheat to Northridge
  %{from_vendor: "northridge", to_vendor: nil, product: "WHEAT-BU", role: :downstream},
  # QuickHaul provides logistics from Acme to us
  %{from_vendor: "quickhaul", to_vendor: nil, product: "TRUCK-MI", role: :logistics}
]

Enum.each(sample_links, fn link ->
  attrs = %{
    from_vendor_id: vendors_by_slug[link.from_vendor].id,
    to_vendor_id: link.to_vendor && vendors_by_slug[link.to_vendor].id,
    product_id: products_by_sku[link.product].id,
    role: link.role,
    active: true
  }

  exists? =
    Repo.get_by(SupplyLink,
      from_vendor_id: attrs.from_vendor_id,
      product_id: attrs.product_id,
      role: Atom.to_string(link.role)
    )

  unless exists? do
    %SupplyLink{}
    |> SupplyLink.changeset(attrs)
    |> Repo.insert!()
  end
end)

IO.puts("Seeded #{length(sample_links)} supply links")

# --- Sample posted journal entry ------------------------------------------
unless Repo.get_by(JournalEntry, reference: "PO-0001") do
  cash = Repo.get_by!(Account, code: "1000")
  seed_exp = Repo.get_by!(Account, code: "5100")

  %JournalEntry{}
  |> JournalEntry.changeset(%{
    posted_on: Date.utc_today(),
    memo: "Initial corn seed purchase",
    reference: "PO-0001",
    posted: true,
    vendor_id: vendors_by_slug["acme-seed"].id,
    created_by_user_id: admin.id,
    lines: [
      %{account_id: seed_exp.id, debit: Money.new(:USD, "500.00"), line_memo: "10 bags corn seed"},
      %{account_id: cash.id, credit: Money.new(:USD, "500.00"), line_memo: "Paid by check"}
    ]
  })
  |> Repo.insert!()

  IO.puts("Seeded sample journal entry PO-0001")
end

IO.puts("Done.")
