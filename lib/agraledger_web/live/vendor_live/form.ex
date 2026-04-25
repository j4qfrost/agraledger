defmodule AgraledgerWeb.VendorLive.Form do
  use AgraledgerWeb, :live_view

  alias Agraledger.Directory
  alias Agraledger.Directory.Vendor

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage vendor records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="vendor-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:slug]} type="text" label="Slug" />
        <.input
          field={@form[:kind]}
          type="select"
          label="Kind"
          options={Enum.map(Agraledger.Directory.Vendor.kinds(), &{Phoenix.Naming.humanize(&1), &1})}
        />
        <.input field={@form[:tax_id]} type="text" label="Tax ID" />
        <.input field={@form[:website]} type="text" label="Website" />
        <.input field={@form[:notes]} type="textarea" label="Notes" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Vendor</.button>
          <.button navigate={return_path(@return_to, @vendor)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    vendor = Directory.get_vendor!(id)

    socket
    |> assign(:page_title, "Edit Vendor")
    |> assign(:vendor, vendor)
    |> assign(:form, to_form(Directory.change_vendor(vendor)))
  end

  defp apply_action(socket, :new, _params) do
    vendor = %Vendor{}

    socket
    |> assign(:page_title, "New Vendor")
    |> assign(:vendor, vendor)
    |> assign(:form, to_form(Directory.change_vendor(vendor)))
  end

  @impl true
  def handle_event("validate", %{"vendor" => vendor_params}, socket) do
    changeset = Directory.change_vendor(socket.assigns.vendor, vendor_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"vendor" => vendor_params}, socket) do
    save_vendor(socket, socket.assigns.live_action, vendor_params)
  end

  defp save_vendor(socket, :edit, vendor_params) do
    case Directory.update_vendor(socket.assigns.vendor, vendor_params) do
      {:ok, vendor} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vendor updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, vendor))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_vendor(socket, :new, vendor_params) do
    case Directory.create_vendor(vendor_params) do
      {:ok, vendor} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vendor created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, vendor))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _vendor), do: ~p"/vendors"
  defp return_path("show", vendor), do: ~p"/vendors/#{vendor}"
end
