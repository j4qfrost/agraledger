defmodule Agraledger.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:seed, :feed, :equipment, :produce, :service, :other]
  @units [:kg, :ton, :each, :hour, :acre, :bushel, :liter, :gallon]

  schema "products" do
    field :name, :string
    field :sku, :string
    field :category, Ecto.Enum, values: @categories, default: :other
    field :unit, Ecto.Enum, values: @units, default: :each
    field :default_price, Money.Ecto.Composite.Type

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories
  def units, do: @units

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :category, :unit, :default_price])
    |> validate_required([:name, :sku, :category, :unit])
    |> validate_format(:sku, ~r/^[A-Z0-9][A-Z0-9-]*$/,
      message: "must be uppercase letters, numbers, and dashes"
    )
    |> unique_constraint(:sku)
  end
end
