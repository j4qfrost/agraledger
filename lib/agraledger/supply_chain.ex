defmodule Agraledger.SupplyChain do
  @moduledoc """
  The SupplyChain context.
  """

  import Ecto.Query, warn: false
  alias Agraledger.Repo

  alias Agraledger.SupplyChain.SupplyLink
  alias Agraledger.Directory.Vendor
  alias Agraledger.Catalog.Product

  @us_node_id "us"

  @doc """
  Returns nodes and edges suitable for vis-network.
  Includes a synthetic "us" node representing the operating organization.
  """
  def graph_data do
    vendors = Repo.all(Vendor)
    links = Repo.all(SupplyLink) |> Repo.preload(:product)

    nodes =
      [%{id: @us_node_id, label: "Us", group: "us"}] ++
        Enum.map(vendors, fn v ->
          %{id: "v#{v.id}", label: v.name, group: to_string(v.kind)}
        end)

    edges =
      Enum.map(links, fn link ->
        from_id = "v#{link.from_vendor_id}"
        to_id = if link.to_vendor_id, do: "v#{link.to_vendor_id}", else: @us_node_id

        %{
          id: link.id,
          from: from_id,
          to: to_id,
          label: edge_label(link),
          arrows: "to",
          dashes: not link.active
        }
      end)

    %{nodes: nodes, edges: edges}
  end

  defp edge_label(%SupplyLink{product: %Product{name: name}}), do: name
  defp edge_label(%SupplyLink{role: role}), do: to_string(role)

  @doc """
  Returns the list of supply_links.

  ## Examples

      iex> list_supply_links()
      [%SupplyLink{}, ...]

  """
  def list_supply_links do
    Repo.all(SupplyLink)
  end

  @doc """
  Gets a single supply_link.

  Raises `Ecto.NoResultsError` if the Supply link does not exist.

  ## Examples

      iex> get_supply_link!(123)
      %SupplyLink{}

      iex> get_supply_link!(456)
      ** (Ecto.NoResultsError)

  """
  def get_supply_link!(id), do: Repo.get!(SupplyLink, id)

  @doc """
  Creates a supply_link.

  ## Examples

      iex> create_supply_link(%{field: value})
      {:ok, %SupplyLink{}}

      iex> create_supply_link(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_supply_link(attrs) do
    %SupplyLink{}
    |> SupplyLink.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supply_link.

  ## Examples

      iex> update_supply_link(supply_link, %{field: new_value})
      {:ok, %SupplyLink{}}

      iex> update_supply_link(supply_link, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_supply_link(%SupplyLink{} = supply_link, attrs) do
    supply_link
    |> SupplyLink.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a supply_link.

  ## Examples

      iex> delete_supply_link(supply_link)
      {:ok, %SupplyLink{}}

      iex> delete_supply_link(supply_link)
      {:error, %Ecto.Changeset{}}

  """
  def delete_supply_link(%SupplyLink{} = supply_link) do
    Repo.delete(supply_link)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supply_link changes.

  ## Examples

      iex> change_supply_link(supply_link)
      %Ecto.Changeset{data: %SupplyLink{}}

  """
  def change_supply_link(%SupplyLink{} = supply_link, attrs \\ %{}) do
    SupplyLink.changeset(supply_link, attrs)
  end
end
