defmodule Nimble.UserView do
  use Nimble.Web, :view

  alias Nimble.UserTokenView
  alias Nimble.UserView

  def render("show.json", %{user: user}) do
    %{
      ok: true,
      data: %{
        user: render_one(user, UserView, "user.json", as: :user)
      }
    }
  end

  def render("login.json", %{user: user}) do
    %{
      ok: true,
      data: %{
        user: render_one(user, UserView, "user.json", as: :user)
      }
    }
  end

  def render("ok.json", _) do
    %{
      ok: true
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      firstName: user.first_name,
      email: user.email,
      confirmedAt: user.confirmed_at,
      isAdmin: user.is_admin
    }
  end

  def render("sessions.json", %{tokens: tokens}) do
    %{
      ok: true,
      data: %{
        tokens: render_many(tokens, UserTokenView, "token.json", as: :token)
      }
    }
  end

  def render("session.json", %{token: token}) do
    %{
      ok: true,
      data: %{
        token: render_one(token, UserTokenView, "token.json", as: :token)
      }
    }
  end

  def render("get_provider.json", %{url: url}) do
    %{
      ok: true,
      data: %{
        url: url
      }
    }
  end
end
