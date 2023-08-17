defmodule Nimble.Auth.EnsureAuth do
  @moduledoc false
  use Phoenix.Controller

  import Plug.Conn

  def init(opts), do: opts

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def call(conn, _opts \\ %{}) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(Nimble.ErrorJSON)
      |> render("error.json", error: "You do not have access to this resource.")
      |> halt()
    end
  end
end
