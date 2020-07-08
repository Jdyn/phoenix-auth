defmodule Nimble.Service.Users do
  alias Nimble.{User, Repo, Token}

  @doc """
  Retrieve a User by a parameter that exists on a %User{} struct.

  ## Examples

      iex> find_by(email: "test@test.com")
      %User{}

      iex> find_by(id: 105)
      nil
  """
  def find_by(param) do
    Repo.get_by(User, param)
  end

  @doc """
  Retrieve a User by a given signed session token.
  """
  def find_by_session_token(token) do
    {:ok, query} = Token.verify_session_token_query(token)
    Repo.one(query)
  end
end
