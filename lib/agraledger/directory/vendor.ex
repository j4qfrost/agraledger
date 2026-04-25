defmodule Agraledger.Directory.Vendor do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds [:supplier, :customer, :both]

  schema "vendors" do
    field :name, :string
    field :slug, :string
    field :kind, Ecto.Enum, values: @kinds, default: :supplier
    field :tax_id, :string
    field :website, :string
    field :notes, :string
    field :tags, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    has_many :contacts, Agraledger.Directory.Contact
    has_many :outgoing_links, Agraledger.SupplyChain.SupplyLink, foreign_key: :from_vendor_id
    has_many :incoming_links, Agraledger.SupplyChain.SupplyLink, foreign_key: :to_vendor_id

    timestamps(type: :utc_datetime)
  end

  def kinds, do: @kinds

  @doc false
  def changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:name, :slug, :kind, :tax_id, :website, :notes, :tags, :metadata])
    |> validate_required([:name, :slug, :kind])
    |> validate_length(:name, max: 200)
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9-]*$/,
      message: "must be lowercase letters, numbers, and dashes"
    )
    |> validate_inclusion(:kind, @kinds)
    |> unique_constraint(:slug)
  end
end
