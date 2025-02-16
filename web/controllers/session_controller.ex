defmodule Nimble.SessionController do
  use Nimble.Web, :controller

  alias Nimble.Sessions

  action_fallback(Nimble.ErrorController)

  @doc """
  Shows all sessions associated with a user.
  """
  def index(conn, _params) do
    current_user = current_user(conn)

    render(conn, :index, tokens: Sessions.find_all_sessions(current_user))
  end

  @doc """
  Shows the current session that the user is requesting from user.
  """
  def show(conn, _params) do
    user = current_user(conn)
    token = get_session(conn, :user_token)
    render(conn, :show, token: Sessions.find_session(user, token: token), user: user)
  end

  @doc """
  Deletes a session associated with a user.
  """
  def delete(conn, %{"tracking_id" => tracking_id}) do
    user = current_user(conn)
    token = get_session(conn, :user_token)

    with :ok <- Sessions.delete_session_token(user, tracking_id, token) do
      json(conn, %{ok: true})
    end
  end

  @doc """
  Deletes all sessions associated with a user, except the current one.
  """
  def delete_all(conn, _params) do
    user = current_user(conn)
    token = get_session(conn, :user_token)

    token = Sessions.delete_session_tokens(user, token)
    render(conn, :index, tokens: [token])
  end
end
