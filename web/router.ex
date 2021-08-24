defmodule Nimble.Router do
  use Nimble.Web, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
  end

  pipeline :ensure_auth do
    plug(:fetch_session)
    plug(Nimble.Auth.FetchUser)
    plug(Nimble.Auth.EnsureAuth)
  end

  scope "/api", Nimble do
    pipe_through(:api)

    resources("/account", UserController, singleton: true, only: []) do
      post("/signup", UserController, :sign_up)
      post("/signin", UserController, :sign_in)
    end
  end

  scope "/api", Nimble do
    pipe_through([:api, :ensure_auth])

    resources("/account", UserController, singleton: true, only: [:show]) do
      get("/sessions", UserController, :show_sessions)
      delete("/sessions/:tracker_id", UserController, :delete_session)
      delete("/signout", UserController, :sign_out)
    end
  end
end
