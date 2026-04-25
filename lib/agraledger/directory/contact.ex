defmodule Agraledger.Directory.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :name, :string
    field :role, :string
    field :email, :string
    field :phone, :string
    field :notes, :string
    field :is_primary, :boolean, default: false

    belongs_to :vendor, Agraledger.Directory.Vendor

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :role, :email, :phone, :notes, :is_primary, :vendor_id])
    |> validate_required([:name, :vendor_id])
    |> validate_format(:email, ~r/^[^@\s]+@[^@\s]+$/, message: "must be a valid email")
    |> assoc_constraint(:vendor)
  end
end
