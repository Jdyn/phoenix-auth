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

  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # if Mix.env() in [:dev, :test] do
  #   import Phoenix.LiveDashboard.Router
  #   scope "/" do
  #     pipe_through([:fetch_session, :protect_from_forgery])
  #     live_dashboard("/dashboard", metrics: Nimble.Telemetry)
  #   end
  # end

  scope "/api/v1", Nimble do
    pipe_through(:api)

    post("/account/signup", UserController, :sign_up)
    post("/account/login", UserController, :log_in)
  end

  scope "/api/v1", Nimble do
    pipe_through([:api, :ensure_auth])

    get("/account", UserController, :show)
    get("/account/sessions", UserController, :show_sessions)
    delete("/account/logout", UserController, :log_out)

  end
end
