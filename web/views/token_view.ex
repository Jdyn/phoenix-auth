defmodule Nimble.TokenView do
  use Nimble.Web, :view

  alias Nimble.{UserView}

  def render("token.json", %{token: token}) do
    %{
      token: Base.url_encode64(token.token, padding: false),
      context: token.context,
      insertedAt: token.inserted_at,
      user: render_one(token.user, UserView, "user.json", as: :user)
    }
  end
end
