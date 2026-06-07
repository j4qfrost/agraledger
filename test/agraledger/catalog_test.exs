defmodule Agraledger.CatalogTest do
  use Agraledger.DataCase, async: true

  alias Agraledger.Catalog
  alias Agraledger.Catalog.Product

  import Agraledger.CatalogFixtures

  describe "products" do
    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Catalog.list_products() |> Enum.map(& &1.id) == [product.id]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Catalog.get_product!(product.id).id == product.id
    end

    test "get_product!/1 raises for a missing product" do
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_product!(-1) end
    end

    test "create_product/1 with valid data creates a product" do
      attrs = valid_product_attributes(name: "Alfalfa Seed", sku: "ALF-001", category: :seed)
      assert {:ok, %Product{} = product} = Catalog.create_product(attrs)
      assert product.name == "Alfalfa Seed"
      assert product.sku == "ALF-001"
      assert product.category == :seed
    end

    test "create_product/1 requires name and sku" do
      assert {:error, changeset} = Catalog.create_product(%{})
      assert %{name: ["can't be blank"], sku: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_product/1 rejects a lowercase sku" do
      attrs = valid_product_attributes(sku: "bad sku")
      assert {:error, changeset} = Catalog.create_product(attrs)
      assert %{sku: [_ | _]} = errors_on(changeset)
    end

    test "create_product/1 enforces unique sku" do
      product = product_fixture()
      attrs = valid_product_attributes(sku: product.sku)
      assert {:error, changeset} = Catalog.create_product(attrs)
      assert %{sku: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      assert {:ok, %Product{} = updated} = Catalog.update_product(product, %{name: "Renamed"})
      assert updated.name == "Renamed"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_product(product, %{name: nil})
      assert Catalog.get_product!(product.id).name == product.name
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Catalog.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Catalog.change_product(product)
    end
  end
end
