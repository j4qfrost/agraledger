defmodule AgraledgerWeb.VendorLive.Show do
  use AgraledgerWeb, :live_view

  alias Agraledger.Directory

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Vendor {@vendor.id}
        <:subtitle>This is a vendor record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/vendors"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/vendors/#{@vendor}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit vendor
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@vendor.name}</:item>
        <:item title="Slug">{@vendor.slug}</:item>
        <:item title="Kind">{@vendor.kind}</:item>
        <:item title="Tax">{@vendor.tax_id}</:item>
        <:item title="Website">{@vendor.website}</:item>
        <:item title="Notes">{@vendor.notes}</:item>
        <:item title="Tags">{@vendor.tags}</:item>
        <:item title="Metadata">{@vendor.metadata}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Vendor")
     |> assign(:vendor, Directory.get_vendor!(id))}
  end
end
