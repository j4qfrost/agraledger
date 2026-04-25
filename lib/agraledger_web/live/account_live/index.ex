defmodule AgraledgerWeb.AccountLive.Index do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Chart of accounts")
     |> assign(:accounts, Ledger.list_accounts())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Chart of accounts</h1>
      </.header>

      <table class="table table-zebra">
        <thead><tr><th>Code</th><th>Name</th><th>Type</th><th>Postable?</th></tr></thead>
        <tbody>
          <tr :for={a <- @accounts}>
            <td class="font-mono">{a.code}</td>
            <td>{a.name}</td>
            <td><span class="badge">{a.type}</span></td>
            <td>{if a.is_postable, do: "✓", else: ""}</td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
