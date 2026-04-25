defmodule AgraledgerWeb.ContactLive.Index do
  use AgraledgerWeb, :live_view

  alias Agraledger.Directory

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Contacts
        <:actions>
          <.button variant="primary" navigate={~p"/contacts/new"}>
            <.icon name="hero-plus" /> New Contact
          </.button>
        </:actions>
      </.header>

      <.table
        id="contacts"
        rows={@streams.contacts}
        row_click={fn {_id, contact} -> JS.navigate(~p"/contacts/#{contact}") end}
      >
        <:col :let={{_id, contact}} label="Name">{contact.name}</:col>
        <:col :let={{_id, contact}} label="Role">{contact.role}</:col>
        <:col :let={{_id, contact}} label="Email">{contact.email}</:col>
        <:col :let={{_id, contact}} label="Phone">{contact.phone}</:col>
        <:col :let={{_id, contact}} label="Notes">{contact.notes}</:col>
        <:col :let={{_id, contact}} label="Is primary">{contact.is_primary}</:col>
        <:action :let={{_id, contact}}>
          <div class="sr-only">
            <.link navigate={~p"/contacts/#{contact}"}>Show</.link>
          </div>
          <.link navigate={~p"/contacts/#{contact}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, contact}}>
          <.link
            phx-click={JS.push("delete", value: %{id: contact.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Contacts")
     |> stream(:contacts, list_contacts())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contact = Directory.get_contact!(id)
    {:ok, _} = Directory.delete_contact(contact)

    {:noreply, stream_delete(socket, :contacts, contact)}
  end

  defp list_contacts() do
    Directory.list_contacts()
  end
end
