defmodule Nimble.AccountJSON do
  alias Nimble.User
  alias Nimble.UserToken

  def index(%{users: users}) do
    for(user <- users, do: user(user))
  end

  def show(%{user: user}) do
    user(user)
  end

  def get_provider(%{url: url}) do
    %{
      url: url
    }
  end

  def user(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      phone: user.phone,
      username: user.username,
      confirmedAt: user.confirmed_at
    }
  end

  def token(%UserToken{} = token) do
    %{
      token: Base.url_encode64(token.token, padding: false),
      trackingId: token.tracking_id,
      context: token.context,
      insertedAt: token.inserted_at
    }
  end
end
