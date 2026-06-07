defmodule Agraledger.DirectoryFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Agraledger.Directory` context.
  """

  alias Agraledger.Directory

  def unique_vendor_slug, do: "vendor-#{System.unique_integer([:positive])}"

  def valid_vendor_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Vendor",
      slug: unique_vendor_slug(),
      kind: :supplier
    })
  end

  def vendor_fixture(attrs \\ %{}) do
    {:ok, vendor} =
      attrs
      |> valid_vendor_attributes()
      |> Directory.create_vendor()

    vendor
  end

  def valid_contact_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Contact",
      email: "contact#{System.unique_integer([:positive])}@example.com"
    })
  end

  def contact_fixture(attrs \\ %{}) do
    vendor_id = attrs[:vendor_id] || vendor_fixture().id

    {:ok, contact} =
      attrs
      |> Map.new()
      |> Map.put(:vendor_id, vendor_id)
      |> valid_contact_attributes()
      |> Directory.create_contact()

    contact
  end
end
