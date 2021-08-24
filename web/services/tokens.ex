defmodule Nimble.Service.Tokens do
  alias Nimble.{Repo, Token, User}

  @doc """
  Generates a session token.
  """
  def create_session_token(user) do
    {token, user_token} = Token.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(Token.token_and_context_query(token, "session"))
    :ok
  end

  def delete_session_token(%User{} = user, tracking_id) do
    case Repo.one(Token.user_and_tracker_id_query(user, tracking_id)) do
      nil ->
        {:error, "Session does not exist."}
      token ->
        Repo.delete_all(Token.user_and_tracker_id_query(user, tracking_id))
        {:ok, token |> Repo.preload(:user)}
    end
  end

  @doc """
  Returns all tokens for the given user.
  """
  def find_all(user) do
    Token.user_and_contexts_query(user, :all)
    |> Repo.all()
    |> Repo.preload(:user)
  end
end
