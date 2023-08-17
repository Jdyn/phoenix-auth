defmodule Nimble.UserJSON do
  alias Nimble.User
  alias Nimble.UserTokenJSON

  def show(%{user: user}) do
    %{
      user: user(user)
    }
  end

  def sessions(%{tokens: tokens}) do
    %{
      sessions: for(token <- tokens, do: UserTokenJSON.token(token))
    }
  end

  def session(%{token: token}) do
    %{
      session: UserTokenJSON.token(token)
    }
  end

  def get_provider(%{url: url}) do
    %{
      url: url
    }
  end

  def user(%User{} = user) do
    %{
      id: user.id,
      firstName: user.first_name,
      email: user.email,
      confirmedAt: user.confirmed_at,
      isAdmin: user.is_admin
    }
  end
end
