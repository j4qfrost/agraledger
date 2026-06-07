defmodule Agraledger.SupplyChainTest do
  use Agraledger.DataCase, async: true

  alias Agraledger.SupplyChain
  alias Agraledger.SupplyChain.SupplyLink

  import Agraledger.DirectoryFixtures
  import Agraledger.SupplyChainFixtures

  describe "supply_links" do
    test "list_supply_links/0 returns all supply_links" do
      link = supply_link_fixture()
      assert SupplyChain.list_supply_links() |> Enum.map(& &1.id) == [link.id]
    end

    test "get_supply_link!/1 returns the supply_link with given id" do
      link = supply_link_fixture()
      assert SupplyChain.get_supply_link!(link.id).id == link.id
    end

    test "create_supply_link/1 with valid data creates a supply_link" do
      from = vendor_fixture()
      to = vendor_fixture()

      assert {:ok, %SupplyLink{} = link} =
               SupplyChain.create_supply_link(%{
                 role: :downstream,
                 from_vendor_id: from.id,
                 to_vendor_id: to.id
               })

      assert link.role == :downstream
      assert link.from_vendor_id == from.id
      assert link.to_vendor_id == to.id
    end

    test "create_supply_link/1 requires role and from_vendor_id" do
      assert {:error, changeset} = SupplyChain.create_supply_link(%{})
      assert %{from_vendor_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_supply_link/1 enforces the from_vendor association" do
      assert {:error, changeset} =
               SupplyChain.create_supply_link(%{role: :upstream, from_vendor_id: -1})

      assert %{from_vendor: [_ | _]} = errors_on(changeset)
    end

    test "update_supply_link/2 updates the supply_link" do
      link = supply_link_fixture()

      assert {:ok, %SupplyLink{} = updated} =
               SupplyChain.update_supply_link(link, %{active: false})

      refute updated.active
    end

    test "delete_supply_link/1 deletes the supply_link" do
      link = supply_link_fixture()
      assert {:ok, %SupplyLink{}} = SupplyChain.delete_supply_link(link)
      assert_raise Ecto.NoResultsError, fn -> SupplyChain.get_supply_link!(link.id) end
    end

    test "change_supply_link/1 returns a supply_link changeset" do
      link = supply_link_fixture()
      assert %Ecto.Changeset{} = SupplyChain.change_supply_link(link)
    end
  end

  describe "graph_data/0" do
    test "always includes a synthetic \"us\" node" do
      assert %{nodes: [%{id: "us", group: "us"} | _], edges: _} = SupplyChain.graph_data()
    end

    test "renders a node per vendor and an edge per link" do
      from = vendor_fixture(name: "Upstream Co")
      _link = supply_link_fixture(from_vendor_id: from.id)

      %{nodes: nodes, edges: edges} = SupplyChain.graph_data()

      # "us" node + one vendor node
      assert Enum.any?(nodes, &(&1.id == "v#{from.id}" and &1.label == "Upstream Co"))
      assert length(edges) == 1
      [edge] = edges
      assert edge.from == "v#{from.id}"
      # a link with no to_vendor points at the synthetic "us" node
      assert edge.to == "us"
    end

    test "uses a dashed edge for inactive links" do
      from = vendor_fixture()
      supply_link_fixture(from_vendor_id: from.id, active: false)

      %{edges: [edge]} = SupplyChain.graph_data()
      assert edge.dashes
    end
  end
end
