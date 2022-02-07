defmodule Nimble.Service.Tokens do
  alias Nimble.{Repo, UserToken, User}

  @doc """
  Generates a session token.
  """
  def create_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Deletes the current session token.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def delete_session_token(%User{} = user, tracking_id) do
    if _token = Repo.one(UserToken.user_and_tracking_id_query(user, tracking_id)) do
      Repo.delete_all(UserToken.user_and_tracking_id_query(user, tracking_id))
      :ok
    else
      {:not_found, "Session does not exist."}
    end
  end

  @doc """
  Deletes all session tokens except current session.
  """
  def delete_session_tokens(%User{} = user, token) do
    Repo.delete_all(UserToken.user_and_other_session_tokens(user, token))
    :ok
  end

  @doc """
  Returns all tokens for the given user.
  """
  def find_all(user) do
    UserToken.user_and_contexts_query(user, :all)
    |> Repo.all()
  end
end
