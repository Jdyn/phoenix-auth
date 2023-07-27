defmodule Nimble.UserController do
  use Nimble.Web, :controller

  alias Nimble.Accounts
  alias Nimble.Auth.OAuth

  action_fallback(Nimble.ErrorController)

  # Valid for 30 days.
  @max_age 60 * 60 * 24 * 30
  @remember_me_cookie "remember_token"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def show(conn, _params) do
    token = get_session(conn, :user_token)

    conn
    |> put_remember_token(token)
    |> configure_session(renew: true)
    |> render("show.json", user: conn.assigns[:current_user])
  end

  def show_sessions(conn, _params) do
    current_user = conn.assigns[:current_user]

    tokens = Accounts.find_all_sessions(current_user)
    render(conn, "sessions.json", tokens: tokens)
  end

  @doc """
  Deletes a session associated with a user.
  """
  def delete_session(conn, %{"tracking_id" => tracking_id}) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with :ok <- Accounts.delete_session_token(user, tracking_id, token) do
      render(conn, "ok.json")
    end
  end

  def delete_sessions(conn, _params) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with token <- Accounts.delete_session_tokens(user, token) do
      render(conn, "sessions.json", tokens: [token])
    end
  end

  @doc """
  Creates a user
  Generates a new User and populates the session
  """
  def sign_up(conn, params) do
    with {:ok, user} <- Accounts.register(params, :default) do
      token = Accounts.create_session_token(user)

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
    with {:ok, user} <- Accounts.authenticate(email, password),
         nil <- get_session(conn, :user_token) do
      token = Accounts.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> render("login.json", user: user)
    else
      nil ->
        {:unauthorized, "You are already signed in."}

      error ->
        error
    end
  end

  @doc """
  Logs the user out.
  It clears all session data for safety. See renew_session.
  """
  def sign_out(conn, _params) do
    token = get_session(conn, :user_token)
    token && Accounts.delete_session_token(token)

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> render("ok.json")
  end

  def provider_request(conn, %{"provider" => provider}) do
    with {:ok, %{url: url, session_params: _}} <- OAuth.request(provider) do
      render(conn, "get_provider.json", url: url)
    end
  end

  def provider_callback(conn, %{"provider" => provider} = params) do
    with {:ok, user} <- Accounts.authenticate(provider, params) do
      token = get_session(conn, :user_token)
      token && Accounts.delete_session_token(token)

      token = Accounts.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> put_status(:created)
      |> render("show.json", user: user)
    end
  end

  def send_user_email_confirmation(conn, _params) do
    current_user = conn.assigns[:current_user]

    with user <- Accounts.get_user_by_email(current_user.email),
         :ok <- Accounts.deliver_user_confirmation_instructions(user) do
      render(conn, "ok.json")
    end
  end

  def do_user_email_confirmation(conn, %{"token" => token}) do
    with {:ok, _} <- Accounts.confirm_user_email(token) do
      render(conn, "ok.json")
    end
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
