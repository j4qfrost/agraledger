defmodule Agraledger.SupplyChain.SupplyLink do
  use Ecto.Schema
  import Ecto.Changeset

  @roles [:upstream, :downstream, :logistics]

  schema "supply_links" do
    field :role, Ecto.Enum, values: @roles, default: :upstream
    field :notes, :string
    field :active, :boolean, default: true

    belongs_to :from_vendor, Agraledger.Directory.Vendor
    belongs_to :to_vendor, Agraledger.Directory.Vendor
    belongs_to :product, Agraledger.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  def roles, do: @roles

  @doc false
  def changeset(supply_link, attrs) do
    supply_link
    |> cast(attrs, [:role, :notes, :active, :from_vendor_id, :to_vendor_id, :product_id])
    |> validate_required([:role, :from_vendor_id])
    |> assoc_constraint(:from_vendor)
    |> assoc_constraint(:to_vendor)
    |> assoc_constraint(:product)
  end
end
