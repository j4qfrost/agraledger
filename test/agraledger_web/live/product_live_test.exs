defmodule AgraledgerWeb.ProductLiveTest do
  use AgraledgerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Agraledger.CatalogFixtures

  alias Agraledger.Catalog

  describe "Index (viewer access)" do
    setup :register_and_log_in_user

    test "lists existing products", %{conn: conn} do
      product = product_fixture(name: "Alfalfa Seed")
      {:ok, _lv, html} = live(conn, ~p"/products")
      assert html =~ product.name
    end
  end

  describe "Form (bookkeeper access)" do
    setup :register_and_log_in_bookkeeper

    test "creates a product from valid params", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/products/new")

      lv
      |> form("#product-form",
        product: %{name: "Barley Seed", sku: "BARLEY-1", category: "seed", unit: "kg"}
      )
      |> render_submit()

      assert_redirect(lv, ~p"/products")
      assert [%{sku: "BARLEY-1"}] = Catalog.list_products()
    end

    test "rejects a malformed SKU without creating a product", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/products/new")

      lv
      |> form("#product-form",
        product: %{name: "X", sku: "lower case", category: "seed", unit: "kg"}
      )
      |> render_submit()

      assert Catalog.list_products() == []
    end
  end

  describe "role gating" do
    setup :register_and_log_in_user

    test "a viewer cannot reach the new-product form", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/products/new")
    end
  end
end
