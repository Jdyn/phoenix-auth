defmodule Nimble.UserController do
  use Nimble.Web, :controller

  import Plug.Conn
  import Phoenix.Controller

  alias Nimble.{Accounts, ErrorView, UserView}
  alias Nimble.Service.{Accounts, Tokens}

  # Valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "auth_token"
  @remember_me_options [sign: false, max_age: @max_age]

  def show(conn, _params) do
    conn
    |> put_status(:ok)
    |> put_view(UserView)
    |> render("show.json", user: conn.assigns[:current_user])
  end

  @doc """
  Creates a user
  Generates a new User and populates the session
  """
  def sign_up(conn, params) do
    case Accounts.register(params) do
      {:ok, user} ->
        token = Tokens.create_session_token(user)

        conn
        |> renew_session()
        |> put_session(:user_token, token)
        |> create_remember_token(token)
        |> put_status(:created)
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> put_view(ErrorView)
        |> render("changeset_error.json", changeset: changeset)
    end
  end

  @doc """
  Logs the user in.
  It renews the session ID and clears the whole session
  to avoid fixation attacks.
  """
  def log_in(conn, %{"email" => email, "password" => password} = _params) do
    case Accounts.authenticate(email, password) do
      {:error, reason} ->
        conn
        |> renew_session()
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("error.json", error: reason)

      {:ok, user} ->
        token = Tokens.create_session_token(user)

        conn
        |> renew_session()
        |> put_session(:user_token, token)
        |> create_remember_token(Base.url_encode64(token, padding: false))
        |> put_status(:ok)
        |> put_view(UserView)
        |> render("login.json", %{user: user, token: Base.url_encode64(token, padding: false)})
    end
  end

  @doc """
  Logs the user out.
  It clears all session data for safety. See renew_session.
  """
  def log_out(conn, _params) do
    token = get_session(conn, :user_token)
    token && Tokens.delete_session_token(token)

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> put_status(:ok)
    |> put_view(UserView)
    |> render("ok.json")
  end

  defp create_remember_token(conn, token),
    do: put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
