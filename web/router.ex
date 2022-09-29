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

  if Mix.env() == :dev do
    forward("/mailbox", Plug.Swoosh.MailboxPreview)
  end

  scope "/api", Nimble do
    pipe_through(:api)

    resources("/account", UserController, singleton: true, only: []) do
      post("/signup", UserController, :sign_up)
      post("/signin", UserController, :sign_in)
      get("/:provider/request", UserController, :provider_request)
      get("/:provider/callback", UserController, :provider_callback)
    end
  end

  scope "/api", Nimble do
    pipe_through([:api, :ensure_auth])

    resources("/account", UserController, singleton: true, only: [:show]) do
      get("/sessions", UserController, :show_sessions)
      get("/email/confirm", UserController, :send_user_email_confirmation)
      post("/email/confirm/:token", UserController, :do_user_email_confirmation)
      delete("/sessions/clear", UserController, :delete_sessions)
      delete("/sessions/:tracking_id", UserController, :delete_session)
      delete("/signout", UserController, :sign_out)
    end
  end
end
