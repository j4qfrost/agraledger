defmodule AgraledgerWeb.ContactLive.Show do
  use AgraledgerWeb, :live_view

  alias Agraledger.Directory

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Contact {@contact.id}
        <:subtitle>This is a contact record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/contacts"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/contacts/#{@contact}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit contact
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@contact.name}</:item>
        <:item title="Role">{@contact.role}</:item>
        <:item title="Email">{@contact.email}</:item>
        <:item title="Phone">{@contact.phone}</:item>
        <:item title="Notes">{@contact.notes}</:item>
        <:item title="Is primary">{@contact.is_primary}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Contact")
     |> assign(:contact, Directory.get_contact!(id))}
  end
end
