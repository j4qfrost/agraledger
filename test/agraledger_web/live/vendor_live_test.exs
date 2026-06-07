defmodule AgraledgerWeb.VendorLiveTest do
  use AgraledgerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Agraledger.DirectoryFixtures

  alias Agraledger.Directory

  describe "Index (viewer access)" do
    setup :register_and_log_in_user

    test "lists existing vendors", %{conn: conn} do
      vendor = vendor_fixture(name: "Green Acres Co")
      {:ok, _lv, html} = live(conn, ~p"/vendors")
      assert html =~ "Listing Vendors"
      assert html =~ vendor.name
    end
  end

  describe "role gating" do
    setup :register_and_log_in_user

    test "a viewer cannot reach the new-vendor form", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/vendors/new")
    end

    test "a viewer cannot reach the edit-vendor form", %{conn: conn} do
      vendor = vendor_fixture()
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/vendors/#{vendor}/edit")
    end
  end

  describe "Form (bookkeeper access)" do
    setup :register_and_log_in_bookkeeper

    test "creates a vendor from valid params", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/new")

      lv
      |> form("#vendor-form", vendor: %{name: "Acme Farms", slug: "acme-farms", kind: "supplier"})
      |> render_submit()

      assert_redirect(lv, ~p"/vendors")
      assert [%{name: "Acme Farms"}] = Directory.list_vendors()
    end

    test "rejects invalid params without creating a vendor", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/new")

      html =
        lv
        |> form("#vendor-form", vendor: %{name: "", slug: "Bad Slug", kind: "supplier"})
        |> render_submit()

      assert html =~ "vendor-form"
      assert Directory.list_vendors() == []
    end

    test "edits an existing vendor", %{conn: conn} do
      vendor = vendor_fixture(name: "Old Name")
      {:ok, lv, _html} = live(conn, ~p"/vendors/#{vendor}/edit")

      lv
      |> form("#vendor-form", vendor: %{name: "New Name"})
      |> render_submit()

      assert_redirect(lv, ~p"/vendors")
      assert Directory.get_vendor!(vendor.id).name == "New Name"
    end
  end
end
