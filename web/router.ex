defmodule Nimble.Router do
  use Nimble.Web, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
  end

  pipeline :ensure_auth do
    plug(Nimble.Auth.FetchUser)
    plug(Nimble.Auth.EnsureAuth)
  end

  if Mix.env() == :dev, do: forward("/mailbox", Plug.Swoosh.MailboxPreview)

  scope "/api", Nimble do
    pipe_through([:api])

    resources("/account", UserController, singleton: true, only: []) do
      post("/signup", UserController, :sign_up)
      post("/signin", UserController, :sign_in)

      get("/:provider/request", UserController, :provider_request)
      get("/:provider/callback", UserController, :provider_callback)

      post("/password/reset", UserController, :send_reset_password)
      patch("/password/reset/:token", UserController, :do_reset_password)
    end
  end

  scope "/api", Nimble do
    pipe_through([:api, :ensure_auth])

    resources("/account", UserController, singleton: true, only: [:show]) do
      get("/sessions", UserController, :show_sessions)

      post("/email/confirm", UserController, :send_email_confirmation)
      patch("/email/confirm/:token", UserController, :do_email_confirmation)

      post("/email/update", UserController, :send_update_email)
      patch("/email/update/:token", UserController, :do_update_email)

      post("/password/update", UserController, :update_password)

      delete("/sessions/clear", UserController, :delete_sessions)
      delete("/sessions/:tracking_id", UserController, :delete_session)

      delete("/signout", UserController, :sign_out)
    end
  end
end
