defmodule Agraledger.SupplyChainFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Agraledger.SupplyChain` context.
  """

  import Agraledger.DirectoryFixtures

  alias Agraledger.SupplyChain

  def valid_supply_link_attributes(attrs \\ %{}) do
    from_vendor_id = attrs[:from_vendor_id] || vendor_fixture().id

    attrs
    |> Map.new()
    |> Map.put(:from_vendor_id, from_vendor_id)
    |> Enum.into(%{
      role: :upstream,
      active: true
    })
  end

  def supply_link_fixture(attrs \\ %{}) do
    {:ok, supply_link} =
      attrs
      |> valid_supply_link_attributes()
      |> SupplyChain.create_supply_link()

    supply_link
  end
end
