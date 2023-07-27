defmodule Nimble.Mailer do
  @moduledoc false
  use Swoosh.Mailer, otp_app: :nimble, adapter: Swoosh.Adapters.Local
end
