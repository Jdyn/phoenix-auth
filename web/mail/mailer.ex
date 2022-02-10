defmodule Nimble.Mailer do
  use Swoosh.Mailer, otp_app: :nimble, adapter: Swoosh.Adapters.Local
end
