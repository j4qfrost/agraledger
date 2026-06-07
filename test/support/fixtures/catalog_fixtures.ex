defmodule Agraledger.CatalogFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Agraledger.Catalog` context.
  """

  alias Agraledger.Catalog

  def unique_product_sku, do: "SKU-#{System.unique_integer([:positive])}"

  def valid_product_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Product",
      sku: unique_product_sku(),
      category: :seed,
      unit: :kg,
      default_price: Money.new(:USD, "12.50")
    })
  end

  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> valid_product_attributes()
      |> Catalog.create_product()

    product
  end
end
