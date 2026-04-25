defmodule AgraledgerWeb.AdminLive.UserIndex do
  use AgraledgerWeb, :live_view
  alias Agraledger.Repo
  alias Agraledger.Accounts.User
  import Ecto.Query

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Users")
     |> load_users()}
  end

  defp load_users(socket), do: assign(socket, :users, Repo.all(from u in User, order_by: u.email))

  def handle_event("set_role", %{"user_id" => user_id, "role" => role}, socket) do
    user = Repo.get!(User, user_id)
    {:ok, _} = user |> User.admin_changeset(%{"role" => role}) |> Repo.update()
    {:noreply, socket |> put_flash(:info, "Role updated") |> load_users()}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <h1>Users</h1>
        <:subtitle>Set the role for each team member</:subtitle>
      </.header>

      <table class="table table-zebra">
        <thead><tr><th>Email</th><th>Name</th><th>Role</th><th>Confirmed</th></tr></thead>
        <tbody>
          <tr :for={u <- @users}>
            <td>{u.email}</td>
            <td>{u.name}</td>
            <td>
              <form phx-change="set_role">
                <input type="hidden" name="user_id" value={u.id} />
                <select name="role" class="select select-sm">
                  <option :for={r <- Agraledger.Accounts.User.roles()} value={r} selected={u.role == r}>
                    {r}
                  </option>
                </select>
              </form>
            </td>
            <td>{if u.confirmed_at, do: "✓", else: "—"}</td>
          </tr>
        </tbody>
      </table>
    </Layouts.app>
    """
  end
end
