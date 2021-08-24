defmodule Nimble.UserView do
  use Nimble.Web, :view

  alias Nimble.{UserView, TokenView}

  def render("show.json", %{user: user}) do
    %{
      ok: true,
      result: %{
        user: render_one(user, UserView, "user.json", as: :user)
      }
    }
  end

  def render("login.json", %{user: user}) do
    %{
      ok: true,
      result: %{
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
      isAdmin: user.is_admin
    }
  end

  def render("sessions.json", %{tokens: tokens}) do
    %{
      ok: true,
      result: %{
        tokens: render_many(tokens, TokenView, "token.json", as: :token)
      }
    }
  end

  def render("session.json", %{token: token}) do
    %{
      ok: true,
      result: %{
        token: render_one(token, TokenView, "token.json", as: :token)
      }
    }
  end
end
