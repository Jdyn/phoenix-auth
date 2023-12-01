defmodule Nimble.SessionJSON do
  alias Nimble.AccountJSON

  def index(%{tokens: tokens}) do
    for(token <- tokens, do: AccountJSON.token(token))
  end

  def show(%{token: token, user: user}) do
    Map.merge(AccountJSON.token(token), %{ user: AccountJSON.user(user) })
  end
end
