defmodule Nimble.UserTokenView do
  use Nimble.Web, :view

  def render("token.json", %{token: token}) do
    %{
      token: Base.url_encode64(token.token, padding: false),
      trackingId: token.tracking_id,
      context: token.context,
      insertedAt: token.inserted_at
    }
  end
end
