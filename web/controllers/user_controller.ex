defmodule Nimble.UserController do
  use Nimble.Web, :controller

  import Plug.Conn
  import Phoenix.Controller

  alias Nimble.{ErrorView, UserView}
  alias Nimble.Service.{Accounts, Users, Tokens}

  # Valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "remember_token"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def show(conn, _params) do
    token = get_session(conn, :user_token)

    conn
    |> put_status(:ok)
    |> put_remember_token(token)
    |> configure_session(renew: true)
    |> put_view(UserView)
    |> render("show.json", user: conn.assigns[:current_user])
  end

  def show_sessions(conn, _params) do
    current_user = conn.assigns[:current_user]

    tokens = Tokens.find_all(current_user)

    conn
    |> put_status(:ok)
    |> put_view(UserView)
    |> render("sessions.json", tokens: tokens)
  end

  def delete_session(conn, %{"tracker_id" => tracker_id}) do
    current_user = conn.assigns[:current_user]

    case Tokens.delete_session_token(current_user, tracker_id) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> put_view(ErrorView)
        |> render("error.json", error: reason)

      {:ok, token} ->
        conn
        |> put_status(:ok)
        |> put_view(UserView)
        |> render("session.json", token: token)
    end
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
        |> put_remember_token(token)
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
  def sign_in(conn, %{"email" => email, "password" => password} = _params) do
    # if token = get_session(conn, :user_token) do
    #   user = token && Users.find_by_session_token(token)

    #   render(conn, "login.json", user: user)
    # end

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
        |> put_remember_token(token)
        |> put_status(:ok)
        |> put_view(UserView)
        |> render("login.json", user: user)
    end
  end

  @doc """
  Logs the user out.
  It clears all session data for safety. See renew_session.
  """
  def sign_out(conn, _params) do
    token = get_session(conn, :user_token)
    token && Tokens.delete_session_token(token)

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> put_status(:ok)
    |> put_view(UserView)
    |> render("ok.json")
  end

  defp put_remember_token(conn, token) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
