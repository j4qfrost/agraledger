defmodule AgraledgerWeb.AdminLive.FiscalPeriodIndex do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger
  alias Agraledger.Ledger.FiscalPeriod

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Fiscal periods")
     |> load_periods()
     |> assign(:form, to_form(Ledger.change_fiscal_period(%FiscalPeriod{})))}
  end

  defp load_periods(socket), do: assign(socket, :periods, Ledger.list_fiscal_periods())

  def handle_event("save", %{"fiscal_period" => attrs}, socket) do
    case Ledger.create_fiscal_period(attrs) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Period created")
         |> load_periods()
         |> assign(:form, to_form(Ledger.change_fiscal_period(%FiscalPeriod{})))}

      {:error, cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def handle_event("toggle_closed", %{"id" => id}, socket) do
    period = Ledger.get_fiscal_period!(id)
    {:ok, _} = Ledger.update_fiscal_period(period, %{closed: !period.closed})
    {:noreply, load_periods(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Fiscal periods</h1>
        <:subtitle>Close a period to lock posting into it</:subtitle>
      </.header>

      <.form for={@form} phx-submit="save" class="flex gap-2 items-end mb-6">
        <.input field={@form[:start_date]} type="date" label="Start" />
        <.input field={@form[:end_date]} type="date" label="End" />
        <.button type="submit" variant="primary">Add</.button>
      </.form>

      <table class="table table-zebra">
        <thead><tr><th>Start</th><th>End</th><th>Closed?</th><th></th></tr></thead>
        <tbody>
          <tr :for={p <- @periods}>
            <td>{p.start_date}</td>
            <td>{p.end_date}</td>
            <td>{if p.closed, do: "🔒", else: "🔓"}</td>
            <td>
              <button class="btn btn-sm" phx-click="toggle_closed" phx-value-id={p.id}>
                {if p.closed, do: "Reopen", else: "Close"}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
