defmodule Nimble.UserController do
  use Nimble.Web, :controller

  alias Nimble.Accounts
  alias Nimble.Auth.OAuth
  alias Nimble.User
  alias Nimble.Users

  action_fallback(Nimble.ErrorController)

  # Valid for 30 days.
  @max_age 60 * 60 * 24 * 30
  @remember_me_cookie "remember_token"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "none", secure: true]

  def show(conn, _params) do
    token = get_session(conn, :user_token)

    conn
    |> put_remember_token(token)
    |> configure_session(renew: true)
    |> render(:show, user: conn.assigns[:current_user])
  end

  @doc """
  Shows all sessions associated with a user.
  """
  def show_sessions(conn, _params) do
    current_user = conn.assigns[:current_user]

    tokens = Accounts.find_all_sessions(current_user)
    render(conn, :sessions, tokens: tokens)
  end

  @doc """
  Deletes a session associated with a user.
  """
  def delete_session(conn, %{"tracking_id" => tracking_id}) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with :ok <- Accounts.delete_session_token(user, tracking_id, token) do
      json(conn, %{ok: true})
    end
  end

  def delete_sessions(conn, _params) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with token <- Accounts.delete_session_tokens(user, token) do
      render(conn, :sessions, tokens: [token])
    end
  end

  @doc """
  Creates a new User and populates the session
  """
  def sign_up(conn, params) do
    with {:ok, user} <- Accounts.register(params) do
      token = Accounts.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> put_status(:created)
      |> render(:show, user: user)
    end
  end

  @doc """
  Logs the user in.
  It renews the session ID and clears the whole session
  to avoid fixation attacks.
  """
  def sign_in(conn, %{"identifier" => identifier, "password" => password} = _params) do
    with {:ok, user} <- Accounts.authenticate(identifier, password) do
      token = Accounts.create_session_token(user)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_remember_token(token)
      |> render(:show, user: user)
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
    |> json(%{ok: true})
  end

  def provider_request(conn, %{"provider" => provider}) do
    with {:ok, %{url: url, session_params: _}} <- OAuth.request(provider) do
      render(conn, :get_provider, url: url)
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
      |> render(:show, user: user)
    end
  end

  def send_email_confirmation(conn, _params) do
    current_user = conn.assigns[:current_user]

    with user <- Users.get_by_identifier(current_user.email),
         {:ok, _token} <- Users.deliver_email_confirmation_instructions(user) do
      json(conn, %{ok: true})
    end
  end

  def do_email_confirmation(conn, %{"token" => token}) do
    with {:ok, _} <- Users.confirm_email(token) do
      json(conn, %{ok: true})
    end
  end

  @doc """
  - Accepts a `current_password` and a `user` map of the proposed changes.
  - Sends an email to the current email address to confirm the change.
  - `Returns` a message to check the old email or an error.
  """
  @spec send_update_email(Plug.Conn.t(), %{current_password: String.t(), user: map()}) :: Plug.Conn.t()
  def send_update_email(conn, %{"current_password" => password, "user" => new_user} = _params) do
    current_user = conn.assigns[:current_user]

    with {:ok, prepared_user} <- Users.prepare_email_update(current_user, password, new_user),
         {:ok, _encoded_token} <- Users.deliver_email_update_instructions(prepared_user, current_user.email) do
      json(conn, %{data: "A link to confirm your email change has been sent to the new address."})
    end
  end

  def do_update_email(conn, %{"token" => token}) do
    with :ok <- Users.update_email(conn.assigns[:current_user], token) do
      conn
      |> put_status(:ok)
      |> json(%{data: "Email changed successfully."})
    end
  end

  def send_reset_password(conn, %{"email" => email}) do
    if user = Users.get_by_identifier(email) do
      Users.deliver_password_reset_instructions(user)
    end

    conn
    |> put_status(:accepted)
    |> json(%{data: "If an account with that email exists, we sent you a password reset link."})
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def do_reset_password(conn, params) do
    with user = %User{} <- Accounts.get_user_by_reset_password_token(params["token"]),
         {:ok, _user} <- Users.reset_password(user, params) do
      json(conn, %{data: "Password changed successfully, You may login again."})
    end
  end

  @doc """
  - Accepts a `current_password` and a `user` map of the proposed changes.
  - If the `current password` is correct, it updates the password.
  """
  def update_password(conn, %{"current_password" => old_password, "user" => new_user} = _params) do
    current_user = conn.assigns[:current_user]

    with {:ok, _user} <- Users.update_password(current_user, old_password, new_user) do
      json(conn, %{data: "Password changed successfully."})
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
