defmodule AgraledgerWeb.ReportLive.TrialBalance do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger

  def mount(_params, _session, socket) do
    today = Date.utc_today()
    rows = Ledger.trial_balance(today)

    {totals_d, totals_c} =
      Enum.reduce(rows, {Decimal.new(0), Decimal.new(0)}, fn {_a, d, c}, {td, tc} ->
        {Decimal.add(td, d), Decimal.add(tc, c)}
      end)

    {:ok,
     socket
     |> assign(:page_title, "Trial balance")
     |> assign(:as_of, today)
     |> assign(:rows, rows)
     |> assign(:totals_debit, totals_d)
     |> assign(:totals_credit, totals_c)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Trial balance</h1>
        <:subtitle>As of {@as_of}</:subtitle>
      </.header>

      <table class="table table-zebra">
        <thead><tr><th>Code</th><th>Account</th><th class="text-right">Debit</th><th class="text-right">Credit</th></tr></thead>
        <tbody>
          <tr :for={{a, d, c} <- @rows}>
            <td>{a.code}</td>
            <td>{a.name}</td>
            <td class="text-right">{format_amount(d)}</td>
            <td class="text-right">{format_amount(c)}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr class="font-bold">
            <td colspan="2">Totals</td>
            <td class="text-right">{format_amount(@totals_debit)}</td>
            <td class="text-right">{format_amount(@totals_credit)}</td>
          </tr>
        </tfoot>
      </table>
    </Layouts.app>
    """
  end

  defp format_amount(d) do
    if Decimal.equal?(d, 0), do: "—", else: Decimal.to_string(d, :normal)
  end
end
