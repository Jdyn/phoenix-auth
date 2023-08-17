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
  def token_and_context_query(token, context) do
    from(UserToken, where: [token: ^token, context: ^context])
  end

  @doc """
  Returns all session tokens except EXCEPT for the session token provided.
  """
  def user_and_session_tokens(%User{} = user, token) do
    from(t in UserToken,
      where: t.token != ^token and t.user_id == ^user.id and t.context == "session"
    )
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    from(t in UserToken, where: t.user_id == ^user.id, order_by: [desc: t.inserted_at])
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from(t in UserToken,
      where: t.user_id == ^user.id and t.context in ^contexts,
      order_by: [desc: t.inserted_at]
    )
  end

  @doc """
  Gets the UserToken for the given user and tracking_id.
  """
  def user_and_tracking_id_query(%{id: id} = %User{}, tracking_id) do
    from(t in UserToken, where: t.user_id == ^id and t.tracking_id == ^tracking_id)
  end

  @doc """
  Gets the UserToken for the given user and token.
  """
  def user_and_token_query(%{id: id} = %User{}, token) do
    from(t in UserToken, where: t.user_id == ^id and t.token == ^token)
  end
end
