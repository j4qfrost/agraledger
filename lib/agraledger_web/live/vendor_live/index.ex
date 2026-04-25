defmodule AgraledgerWeb.VendorLive.Index do
  use AgraledgerWeb, :live_view

  alias Agraledger.Directory

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Vendors
        <:actions>
          <.button variant="primary" navigate={~p"/vendors/new"}>
            <.icon name="hero-plus" /> New Vendor
          </.button>
        </:actions>
      </.header>

      <.table
        id="vendors"
        rows={@streams.vendors}
        row_click={fn {_id, vendor} -> JS.navigate(~p"/vendors/#{vendor}") end}
      >
        <:col :let={{_id, vendor}} label="Name">{vendor.name}</:col>
        <:col :let={{_id, vendor}} label="Slug">{vendor.slug}</:col>
        <:col :let={{_id, vendor}} label="Kind">{vendor.kind}</:col>
        <:col :let={{_id, vendor}} label="Tax">{vendor.tax_id}</:col>
        <:col :let={{_id, vendor}} label="Website">{vendor.website}</:col>
        <:col :let={{_id, vendor}} label="Notes">{vendor.notes}</:col>
        <:col :let={{_id, vendor}} label="Tags">{vendor.tags}</:col>
        <:col :let={{_id, vendor}} label="Metadata">{vendor.metadata}</:col>
        <:action :let={{_id, vendor}}>
          <div class="sr-only">
            <.link navigate={~p"/vendors/#{vendor}"}>Show</.link>
          </div>
          <.link navigate={~p"/vendors/#{vendor}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, vendor}}>
          <.link
            phx-click={JS.push("delete", value: %{id: vendor.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Vendors")
     |> stream(:vendors, list_vendors())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vendor = Directory.get_vendor!(id)
    {:ok, _} = Directory.delete_vendor(vendor)

    {:noreply, stream_delete(socket, :vendors, vendor)}
  end

  defp list_vendors() do
    Directory.list_vendors()
  end
end
