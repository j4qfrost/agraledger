defmodule AgraledgerWeb.JournalEntryLive.Index do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Journal entries")
     |> assign(:entries, Ledger.list_journal_entries())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Journal entries</h1>
        <:actions>
          <.button :if={@current_scope.user.role in [:admin, :bookkeeper]} variant="primary" navigate={~p"/ledger/entries/new"}>
            New entry
          </.button>
        </:actions>
      </.header>

      <table class="table table-zebra">
        <thead><tr><th>Date</th><th>Reference</th><th>Memo</th><th>Vendor</th><th>Posted?</th><th></th></tr></thead>
        <tbody>
          <tr :for={e <- @entries}>
            <td>{e.posted_on}</td>
            <td class="font-mono">{e.reference}</td>
            <td>{e.memo}</td>
            <td>{e.vendor && e.vendor.name}</td>
            <td>{if e.posted, do: "✓", else: "draft"}</td>
            <td><.link class="link" navigate={~p"/ledger/entries/#{e}"}>View</.link></td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
