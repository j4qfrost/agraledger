defmodule AgraledgerWeb.SupplyChainLiveTest do
  use AgraledgerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Agraledger.DirectoryFixtures
  import Agraledger.SupplyChainFixtures

  describe "SupplyChain graph" do
    setup :register_and_log_in_user

    test "renders the graph container for an authenticated user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/supply-chain")
      assert has_element?(lv, "#supply-chain-graph")
    end

    test "includes a vendor node when links exist", %{conn: conn} do
      vendor = vendor_fixture(name: "Upstream Supplier")
      supply_link_fixture(from_vendor_id: vendor.id)

      {:ok, _lv, html} = live(conn, ~p"/supply-chain")
      assert html =~ "Upstream Supplier"
    end
  end

  describe "role gating" do
    test "an unauthenticated user is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/supply-chain")
    end
  end
end
