defmodule Nimble.UserTokenJSON do
  alias Nimble.UserToken

  def token(%UserToken{} = token) do
    %{
      token: Base.url_encode64(token.token, padding: false),
      trackingId: token.tracking_id,
      context: token.context,
      insertedAt: token.inserted_at
    }
  end
end
