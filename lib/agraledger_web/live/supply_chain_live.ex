defmodule AgraledgerWeb.SupplyChainLive do
  use AgraledgerWeb, :live_view
  import Ecto.Query
  alias Agraledger.{SupplyChain, Directory, Ledger, Repo}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Supply chain")
     |> assign(:graph, SupplyChain.graph_data())
     |> assign(:selected, nil)}
  end

  def handle_event("select_vendor", %{"id" => "v" <> id_str}, socket) do
    id = String.to_integer(id_str)
    vendor = Directory.get_vendor!(id)
    contacts = Repo.all(from c in Agraledger.Directory.Contact, where: c.vendor_id == ^id)
    entries = Ledger.list_journal_entries(vendor_id: id) |> Enum.take(5)

    {:noreply,
     assign(socket, :selected, %{vendor: vendor, contacts: contacts, entries: entries})}
  end

  def handle_event("select_vendor", %{"id" => "us"}, socket) do
    {:noreply, assign(socket, :selected, :us)}
  end

  def handle_event("select_vendor", _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Supply chain</h1>
        <:subtitle>Vendors, products, and the flows between them</:subtitle>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div
          id="supply-chain-graph"
          phx-hook="SupplyChainGraph"
          phx-update="ignore"
          data-graph={Jason.encode!(@graph)}
          class="lg:col-span-2 bg-base-200 rounded-box border border-base-300"
          style="height: 600px;"
        ></div>

        <aside class="bg-base-200 rounded-box p-4 border border-base-300">
          <%= cond do %>
            <% is_nil(@selected) -> %>
              <p class="opacity-70">Click a node to inspect.</p>
            <% @selected == :us -> %>
              <h3 class="font-bold text-lg">Us</h3>
              <p class="opacity-70">The operating organization.</p>
            <% true -> %>
              <h3 class="font-bold text-lg">{@selected.vendor.name}</h3>
              <p class="badge">{@selected.vendor.kind}</p>
              <h4 class="mt-4 font-semibold">Contacts</h4>
              <ul class="list-disc ml-5">
                <li :for={c <- @selected.contacts}>
                  {c.name} <span class="opacity-70">— {c.role || "—"}</span>
                </li>
              </ul>
              <h4 class="mt-4 font-semibold">Recent entries</h4>
              <ul class="list-disc ml-5">
                <li :for={e <- @selected.entries}>
                  <.link navigate={~p"/ledger/entries/#{e}"}>
                    {e.posted_on} — {e.memo}
                  </.link>
                </li>
              </ul>
          <% end %>
        </aside>
      </div>
    </Layouts.app>
    """
  end
end
