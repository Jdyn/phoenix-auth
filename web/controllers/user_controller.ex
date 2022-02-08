defmodule Nimble.UserController do
  use Nimble.Web, :controller

  import Plug.Conn
  import Phoenix.Controller

  alias Nimble.{UserView}
  alias Nimble.{Identity}

  action_fallback(Nimble.ErrorController)

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
    |> render("show.json", user: conn.assigns[:current_user])
  end

  def show_sessions(conn, _params) do
    current_user = conn.assigns[:current_user]

    tokens = Identity.find_all_sessions(current_user)

    conn
    |> put_status(:ok)
    |> render("sessions.json", tokens: tokens)
  end

  def delete_session(conn, %{"tracking_id" => tracking_id}) do
    current_user = conn.assigns[:current_user]

    with :ok <- Identity.delete_session_token(current_user, tracking_id) do
      render(conn, "ok.json")
    end
  end

  def delete_sessions(conn, _params) do
    current_user = conn.assigns[:current_user]

    with :ok <- Identity.delete_session_tokens(current_user, get_session(conn, :user_token)) do
      render(conn, "ok.json")
    end
  end

  @doc """
  Creates a user
  Generates a new User and populates the session
  """
  def sign_up(conn, params) do
    with {:ok, user} <- Identity.register(params) do
      token = Identity.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> put_status(:created)
      |> render("show.json", user: user)
    end
  end

  @doc """
  Logs the user in.
  It renews the session ID and clears the whole session
  to avoid fixation attacks.
  """
  def sign_in(conn, %{"email" => email, "password" => password} = _params) do
    with {:ok, user} <- Identity.authenticate(email, password),
         nil <- get_session(conn, :user_token) do
      token = Identity.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> put_status(:ok)
      |> put_view(UserView)
      |> render("login.json", user: user)
    else
      _ ->
        {:unauthorized, "You are already signed in."}
    end
  end

  @doc """
  Logs the user out.
  It clears all session data for safety. See renew_session.
  """
  def sign_out(conn, _params) do
    token = get_session(conn, :user_token)
    token && Identity.delete_session_token(token)

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

  def send_user_email_confirmation(conn, _params) do
    current_user = conn.assigns[:current_user]

    if user = Identity.get_user_by_email(current_user.email) do
      Identity.deliver_user_confirmation_instructions(user)
    end

    conn
    |> put_status(:ok)
    |> render("ok.json")
  end

  def user_email_confirmation(conn, %{"token" => token}) do
    with {:ok, _} <- Identity.confirm_user(token) do
      conn
      |> put_status(:ok)
      |> render("ok.json")
    end
  end
end
