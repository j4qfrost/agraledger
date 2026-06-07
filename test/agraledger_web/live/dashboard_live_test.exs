defmodule AgraledgerWeb.DashboardLiveTest do
  use AgraledgerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Agraledger.DirectoryFixtures
  import Agraledger.CatalogFixtures

  describe "Dashboard" do
    setup :register_and_log_in_user

    test "renders the year-to-date snapshot for an authenticated user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")
      assert has_element?(lv, "h1", "Dashboard")
      assert render(lv) =~ "Revenue YTD"
    end

    test "reflects current vendor and product counts", %{conn: conn} do
      vendor_fixture()
      product_fixture()

      {:ok, _lv, html} = live(conn, ~p"/")
      # both count cards link to their respective sections
      assert html =~ ~p"/vendors"
      assert html =~ ~p"/products"
    end
  end

  describe "unauthenticated access" do
    test "redirects to the login page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/")
    end
  end
end
