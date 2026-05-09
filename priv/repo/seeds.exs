alias Agraledger.{Repo, Accounts}
alias Agraledger.Accounts.User
alias Agraledger.Ledger.Account

# --- Admin user (idempotent) -----------------------------------------------
admin_email = "admin@local"

admin_password =
  System.get_env("ADMIN_SEED_PASSWORD") ||
    (:crypto.strong_rand_bytes(18) |> Base.url_encode64(padding: false))

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

IO.puts("Done.")
