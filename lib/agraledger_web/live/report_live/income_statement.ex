defmodule AgraledgerWeb.ReportLive.IncomeStatement do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger

  def mount(_params, _session, socket) do
    today = Date.utc_today()
    ytd_start = Date.new!(today.year, 1, 1)

    {:ok,
     socket
     |> assign(:page_title, "Income statement")
     |> assign(:is, Ledger.income_statement(ytd_start, today))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Income statement</h1>
        <:subtitle>{@is.from} → {@is.to}</:subtitle>
      </.header>

      <dl class="grid grid-cols-2 gap-4 max-w-md">
        <dt class="font-semibold">Revenue</dt>
        <dd class="text-right">{Decimal.to_string(@is.revenue, :normal)}</dd>
        <dt class="font-semibold">Expenses</dt>
        <dd class="text-right">{Decimal.to_string(@is.expenses, :normal)}</dd>
        <dt class="font-semibold border-t pt-2">Net income</dt>
        <dd class="text-right border-t pt-2 font-bold">{Decimal.to_string(@is.net_income, :normal)}</dd>
      </dl>
    </Layouts.app>
    """
  end
end
