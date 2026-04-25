defmodule AgraledgerWeb.JournalEntryLive.Show do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger

  def mount(%{"id" => id}, _session, socket) do
    entry = Ledger.get_journal_entry!(id)

    {:ok,
     socket
     |> assign(:page_title, "Entry #{entry.id}")
     |> assign(:entry, entry)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Entry #{@entry.id}</h1>
        <:subtitle>{@entry.posted_on} · {if @entry.posted, do: "Posted", else: "Draft"}</:subtitle>
        <:actions>
          <.button :if={@current_scope.user.role in [:admin, :bookkeeper]} navigate={~p"/ledger/entries/#{@entry}/edit"}>
            Edit
          </.button>
        </:actions>
      </.header>

      <dl class="grid grid-cols-2 gap-2 max-w-md mb-6">
        <dt>Reference</dt><dd class="font-mono">{@entry.reference}</dd>
        <dt>Memo</dt><dd>{@entry.memo}</dd>
        <dt>Vendor</dt><dd>{@entry.vendor && @entry.vendor.name}</dd>
        <dt>Created by</dt><dd>{@entry.created_by_user && @entry.created_by_user.email}</dd>
      </dl>

      <table class="table table-zebra">
        <thead><tr><th>Account</th><th>Memo</th><th class="text-right">Debit</th><th class="text-right">Credit</th></tr></thead>
        <tbody>
          <tr :for={l <- @entry.lines}>
            <td>{l.account.code} — {l.account.name}</td>
            <td>{l.line_memo}</td>
            <td class="text-right font-mono">{l.debit && Money.to_string!(l.debit)}</td>
            <td class="text-right font-mono">{l.credit && Money.to_string!(l.credit)}</td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
