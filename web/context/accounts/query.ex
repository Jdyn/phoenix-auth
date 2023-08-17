defmodule Nimble.Accounts.Query do
  @moduledoc """
  Defines a module for querying the accounts context.
  """
  use Nimble.Web, :context

  alias Nimble.User
  alias Nimble.UserToken

  @doc """
  Returns the given token with the given context.
  """
  @spec token_and_context_query(String.t(), String.t()) :: Ecto.Query.t()
  def token_and_context_query(token, context) do
    from(UserToken, where: [token: ^token, context: ^context])
  end

  @doc """
  Returns all `UserToken` sessions EXCEPT for the session of the `UserToken.token` provided.
  """
  @spec user_and_session_tokens(User.t(), String.t()) :: Ecto.Query.t()
  def user_and_session_tokens(%User{} = user, token) do
    from(t in UserToken,
      where: t.token != ^token and t.user_id == ^user.id and t.context == "session"
    )
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  @spec user_and_contexts_query(User.t(), [String.t()]) :: Ecto.Query.t()
  def user_and_contexts_query(user, ["all"]) do
    from(t in UserToken, where: t.user_id == ^user.id)
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from(t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts)
  end

  @doc """
  Gets the UserToken for the given user and tracking_id.
  """
  @spec user_and_tracking_id_query(User.t(), String.t()) :: Ecto.Query.t()
  def user_and_tracking_id_query(%{id: id} = %User{}, tracking_id) do
    from(t in UserToken, where: t.user_id == ^id and t.tracking_id == ^tracking_id)
  end

  @doc """
  Gets the `UserToken` for the given `User` and token.

  """
  @spec user_and_token_query(User.t(), String.t()) :: Ecto.Query.t()
  def user_and_token_query(%{id: id} = %User{}, token) do
    from(t in UserToken, where: t.user_id == ^id and t.token == ^token)
  end
end
