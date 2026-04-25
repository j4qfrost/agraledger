defmodule AgraledgerWeb.JournalEntryLive.Form do
  use AgraledgerWeb, :live_view
  alias Agraledger.Ledger
  alias Agraledger.Ledger.{JournalEntry, JournalLine}
  alias Agraledger.Directory

  def mount(params, _session, socket) do
    {entry, action, title} =
      case params do
        %{"id" => id} ->
          e = Ledger.get_journal_entry!(id)
          {e, :edit, "Edit entry"}

        _ ->
          {%JournalEntry{
             posted_on: Date.utc_today(),
             posted: false,
             lines: [%JournalLine{}, %JournalLine{}]
           }, :new, "New journal entry"}
      end

    accounts = Ledger.list_postable_accounts()
    vendors = Directory.list_vendors()

    {:ok,
     socket
     |> assign(:page_title, title)
     |> assign(:action, action)
     |> assign(:entry, entry)
     |> assign(:accounts, accounts)
     |> assign(:vendors, vendors)
     |> assign(:form, to_form(Ledger.change_journal_entry(entry, %{})))}
  end

  def handle_event("validate", %{"journal_entry" => attrs}, socket) do
    cs =
      socket.assigns.entry
      |> Ledger.change_journal_entry(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(cs))}
  end

  def handle_event("save", %{"journal_entry" => attrs}, socket) do
    attrs = Map.put(attrs, "created_by_user_id", socket.assigns.current_scope.user.id)

    save_result =
      case socket.assigns.action do
        :new -> Ledger.create_journal_entry(attrs)
        :edit -> Ledger.update_journal_entry(socket.assigns.entry, attrs)
      end

    case save_result do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry saved")
         |> push_navigate(to: ~p"/ledger/entries/#{entry}")}

      {:error, cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>{@page_title}</h1>
      </.header>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4 max-w-3xl">
        <.input field={@form[:posted_on]} type="date" label="Posted on" />
        <.input field={@form[:reference]} type="text" label="Reference (PO/Invoice)" />
        <.input field={@form[:memo]} type="text" label="Memo" />
        <.input
          field={@form[:vendor_id]}
          type="select"
          label="Vendor (optional)"
          prompt="—"
          options={Enum.map(@vendors, &{&1.name, &1.id})}
        />
        <.input field={@form[:posted]} type="checkbox" label="Posted" />

        <h3 class="text-lg font-semibold mt-6">Lines</h3>
        <table class="table table-sm">
          <thead><tr><th>Account</th><th>Debit</th><th>Credit</th><th>Memo</th></tr></thead>
          <tbody>
            <.inputs_for :let={line} field={@form[:lines]}>
              <tr>
                <td>
                  <.input
                    field={line[:account_id]}
                    type="select"
                    options={Enum.map(@accounts, &{"#{&1.code} #{&1.name}", &1.id})}
                    prompt="—"
                  />
                </td>
                <td><.input field={line[:debit]} type="text" placeholder="USD 100.00" /></td>
                <td><.input field={line[:credit]} type="text" placeholder="USD 100.00" /></td>
                <td><.input field={line[:line_memo]} type="text" /></td>
              </tr>
            </.inputs_for>
          </tbody>
        </table>
        <p class="text-sm opacity-70">
          Enter amounts as <code>USD 100.00</code>. Each line must have either a debit or a credit, never both.
          Debits must equal credits.
        </p>

        <div class="mt-4">
          <.button type="submit" variant="primary">Save</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
