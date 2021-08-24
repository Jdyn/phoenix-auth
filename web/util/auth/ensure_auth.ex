defmodule Nimble.Auth.EnsureAuth do
  import Plug.Conn
  use Phoenix.Controller

  alias Nimble.ErrorView

  def init(opts), do: opts

  @doc """
  Used for routes that require the user to be authenticated.
  If you want to enforce the user e-mail is confirmed before
  they use the application at all, here would be a good place.
  """
  def call(conn, _opts \\ %{}) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(ErrorView)
      |> render("error.json", error: "You do not have access to this resource.")
      |> halt()
    end
  end
end
