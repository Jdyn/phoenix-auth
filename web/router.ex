defmodule Nimble.Router do
  use Nimble, :router

  pipeline :api do
    plug(:accepts, ["json"])
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

  scope "/api", Nimble do
    pipe_through(:api)

    resources("/account", AccountControler, only: [], singleton: true) do
      post("/signup", UserController, :sign_up)
      post("/login", UserController, :log_in)

    end
  end
end
