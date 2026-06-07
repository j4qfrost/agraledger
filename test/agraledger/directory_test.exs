defmodule Agraledger.DirectoryTest do
  use Agraledger.DataCase, async: true

  alias Agraledger.Directory
  alias Agraledger.Directory.{Contact, Vendor}

  import Agraledger.DirectoryFixtures

  describe "vendors" do
    test "list_vendors/0 returns all vendors" do
      vendor = vendor_fixture()
      assert Directory.list_vendors() |> Enum.map(& &1.id) == [vendor.id]
    end

    test "get_vendor!/1 returns the vendor with given id" do
      vendor = vendor_fixture()
      assert Directory.get_vendor!(vendor.id).id == vendor.id
    end

    test "create_vendor/1 with valid data creates a vendor" do
      attrs = valid_vendor_attributes(name: "Green Acres", slug: "green-acres", kind: :customer)
      assert {:ok, %Vendor{} = vendor} = Directory.create_vendor(attrs)
      assert vendor.name == "Green Acres"
      assert vendor.slug == "green-acres"
      assert vendor.kind == :customer
    end

    test "create_vendor/1 requires name, slug, and kind" do
      assert {:error, changeset} = Directory.create_vendor(%{})
      errors = errors_on(changeset)
      assert errors.name == ["can't be blank"]
      assert errors.slug == ["can't be blank"]
    end

    test "create_vendor/1 rejects an uppercase slug" do
      attrs = valid_vendor_attributes(slug: "Bad-Slug")
      assert {:error, changeset} = Directory.create_vendor(attrs)
      assert %{slug: [_ | _]} = errors_on(changeset)
    end

    test "create_vendor/1 enforces unique slug" do
      vendor = vendor_fixture()
      attrs = valid_vendor_attributes(slug: vendor.slug)
      assert {:error, changeset} = Directory.create_vendor(attrs)
      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_vendor/2 with valid data updates the vendor" do
      vendor = vendor_fixture()
      assert {:ok, %Vendor{} = updated} = Directory.update_vendor(vendor, %{name: "Renamed"})
      assert updated.name == "Renamed"
    end

    test "delete_vendor/1 deletes the vendor" do
      vendor = vendor_fixture()
      assert {:ok, %Vendor{}} = Directory.delete_vendor(vendor)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_vendor!(vendor.id) end
    end

    test "change_vendor/1 returns a vendor changeset" do
      vendor = vendor_fixture()
      assert %Ecto.Changeset{} = Directory.change_vendor(vendor)
    end
  end

  describe "contacts" do
    test "list_contacts/0 returns all contacts" do
      contact = contact_fixture()
      assert Directory.list_contacts() |> Enum.map(& &1.id) == [contact.id]
    end

    test "get_contact!/1 returns the contact with given id" do
      contact = contact_fixture()
      assert Directory.get_contact!(contact.id).id == contact.id
    end

    test "create_contact/1 with valid data creates a contact" do
      vendor = vendor_fixture()

      attrs =
        valid_contact_attributes(name: "Jane Farmer", vendor_id: vendor.id, role: "Owner")

      assert {:ok, %Contact{} = contact} = Directory.create_contact(attrs)
      assert contact.name == "Jane Farmer"
      assert contact.vendor_id == vendor.id
    end

    test "create_contact/1 requires name and vendor_id" do
      assert {:error, changeset} = Directory.create_contact(%{})
      errors = errors_on(changeset)
      assert errors.name == ["can't be blank"]
      assert errors.vendor_id == ["can't be blank"]
    end

    test "create_contact/1 rejects an invalid email" do
      vendor = vendor_fixture()
      attrs = valid_contact_attributes(vendor_id: vendor.id, email: "not-an-email")
      assert {:error, changeset} = Directory.create_contact(attrs)
      assert %{email: [_ | _]} = errors_on(changeset)
    end

    test "update_contact/2 updates the contact" do
      contact = contact_fixture()
      assert {:ok, %Contact{} = updated} = Directory.update_contact(contact, %{is_primary: true})
      assert updated.is_primary
    end

    test "delete_contact/1 deletes the contact" do
      contact = contact_fixture()
      assert {:ok, %Contact{}} = Directory.delete_contact(contact)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_contact!(contact.id) end
    end
  end
end
