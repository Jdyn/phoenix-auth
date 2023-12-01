defmodule Nimble.SessionController do
  use Nimble.Web, :controller

  alias Nimble.Sessions

  @doc """
  Shows all sessions associated with a user.
  """
  def show(conn, _params) do
    current_user = conn.assigns[:current_user]

    tokens = Sessions.find_all_sessions(current_user)
    render(conn, :sessions, tokens: tokens)
  end

  @doc """
  Deletes a session associated with a user.
  """
  def delete(conn, %{"id" => tracking_id}) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with :ok <- Sessions.delete_session_token(user, tracking_id, token) do
      json(conn, %{ok: true})
    end
  end

  def delete_all(conn, _params) do
    user = conn.assigns[:current_user]
    token = get_session(conn, :user_token)

    with token <- Sessions.delete_session_tokens(user, token) do
      render(conn, :sessions, tokens: [token])
    end
  end
end
