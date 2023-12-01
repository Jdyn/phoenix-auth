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

    resources("/account", AccountController, singleton: true, only: []) do
      post("/signup", AccountController, :sign_up)
      post("/signin", AccountController, :sign_in)
      get("/:provider/request", AccountController, :provider_request)
      get("/:provider/callback", AccountController, :provider_callback)

      post("/password/reset", AccountController, :send_reset_password)
      patch("/password/reset/:token", AccountController, :do_reset_password)
    end
  end

  scope "/api", Nimble do
    pipe_through([:api, :ensure_auth])

    resources("/account", AccountController, singleton: true, only: [:show]) do
      post("/email/confirm", AccountController, :send_email_confirmation)
      patch("/email/confirm/:token", AccountController, :do_email_confirmation)

      post("/email/update", AccountController, :send_update_email)
      patch("/email/update/:token", AccountController, :do_update_email)

      post("/password/update", AccountController, :update_password)

      get("/session", SessionController, :show)
      get("/sessions", SessionController, :index)
      delete("/sessions", SessionController, :delete_all)
      delete("/sessions/:id", SessionController, :delete)

      delete("/signout", AccountController, :sign_out)
    end
  end
end
