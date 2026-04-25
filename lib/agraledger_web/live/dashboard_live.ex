defmodule AgraledgerWeb.DashboardLive do
  use AgraledgerWeb, :live_view
  alias Agraledger.{Ledger, Directory, Catalog, SupplyChain}

  def mount(_params, _session, socket) do
    today = Date.utc_today()
    ytd_start = Date.new!(today.year, 1, 1)

    bs = Ledger.balance_sheet(today)
    is = Ledger.income_statement(ytd_start, today)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:bs, bs)
     |> assign(:is, is)
     |> assign(:vendor_count, length(Directory.list_vendors()))
     |> assign(:product_count, length(Catalog.list_products()))
     |> assign(:link_count, length(SupplyChain.list_supply_links()))
     |> assign(:recent_entries, Ledger.list_journal_entries() |> Enum.take(5))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Dashboard</h1>
        <:subtitle>Year-to-date snapshot · {@is.from} → {@is.to}</:subtitle>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Assets</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@bs.assets, :normal)}</div>
        </div></div>
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Liabilities</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@bs.liabilities, :normal)}</div>
        </div></div>
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Equity</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@bs.equity, :normal)}</div>
        </div></div>
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Revenue YTD</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@is.revenue, :normal)}</div>
        </div></div>
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Expenses YTD</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@is.expenses, :normal)}</div>
        </div></div>
        <div class="card bg-base-200 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Net income YTD</div>
          <div class="text-2xl font-bold">${Decimal.to_string(@is.net_income, :normal)}</div>
        </div></div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
        <.link navigate={~p"/vendors"} class="card bg-base-200 hover:bg-base-300 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Vendors</div>
          <div class="text-2xl font-bold">{@vendor_count}</div>
        </div></.link>
        <.link navigate={~p"/products"} class="card bg-base-200 hover:bg-base-300 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Products</div>
          <div class="text-2xl font-bold">{@product_count}</div>
        </div></.link>
        <.link navigate={~p"/supply-chain"} class="card bg-base-200 hover:bg-base-300 shadow"><div class="card-body">
          <div class="text-sm opacity-70">Supply links</div>
          <div class="text-2xl font-bold">{@link_count}</div>
        </div></.link>
      </div>

      <h2 class="text-xl font-semibold mt-8 mb-2">Recent journal entries</h2>
      <table class="table table-zebra">
        <thead><tr><th>Date</th><th>Memo</th><th>Reference</th><th>Posted?</th></tr></thead>
        <tbody>
          <tr :for={e <- @recent_entries}>
            <td><.link navigate={~p"/ledger/entries/#{e}"}>{e.posted_on}</.link></td>
            <td>{e.memo}</td>
            <td>{e.reference}</td>
            <td>{if e.posted, do: "✓", else: "draft"}</td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
