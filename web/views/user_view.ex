defmodule Nimble.UserView do
  use Nimble.Web, :view

  alias Nimble.{UserView}

  def render("show.json", %{user: user}) do
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
      email: user.email
    }
  end
end
