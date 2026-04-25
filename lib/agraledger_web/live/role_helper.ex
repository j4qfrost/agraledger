defmodule AgraledgerWeb.RoleHelper do
  @moduledoc """
  LiveView `on_mount` hooks that gate access by user role.

  Use as `on_mount: {AgraledgerWeb.RoleHelper, :require_admin}` etc.
  Assumes the user has already been authenticated by `UserAuth.require_authenticated`.
  """
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [redirect: 2, put_flash: 3]

  def on_mount(:require_admin, _params, _session, socket),
    do: ensure_role(socket, [:admin])

  def on_mount(:require_bookkeeper, _params, _session, socket),
    do: ensure_role(socket, [:admin, :bookkeeper])

  def on_mount(:require_viewer, _params, _session, socket),
    do: ensure_role(socket, [:admin, :bookkeeper, :viewer])

  defp ensure_role(socket, allowed) do
    user = socket.assigns[:current_scope] && socket.assigns.current_scope.user

    cond do
      is_nil(user) ->
        {:halt,
         socket
         |> put_flash(:error, "You must log in.")
         |> redirect(to: "/users/log-in")}

      user.role in allowed ->
        {:cont, assign(socket, :current_user, user)}

      true ->
        {:halt,
         socket
         |> put_flash(:error, "You don't have permission to view that page.")
         |> redirect(to: "/")}
    end
  end
end
