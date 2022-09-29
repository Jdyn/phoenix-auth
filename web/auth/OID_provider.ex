defmodule Nimble.Auth.OIDProvider do
  alias Assent.Config

  def request(provider) do
    if config = config(String.to_atom(provider)) do
      redirect_uri = "http://localhost:4000/api/account/#{provider}/callback"

      config = Config.put(config, :redirect_uri, redirect_uri)
      strategy = config[:strategy]
      strategy.authorize_url(config)
    else
      {:not_found, "No provider configuration for #{provider}"}
    end
  end

  def callback(provider, params, session_params \\ %{}) do
    if config = config(String.to_atom(provider)) do
      redirect_uri = "http://localhost:4000/api/account/#{provider}/callback"

      config =
        config
        |> Config.put(:session_params, session_params)
        |> Config.put(:redirect_uri, redirect_uri)

      strategy = config[:strategy]
      strategy.callback(config, params)
    else
      {:not_found, "Invalid callback"}
    end
  end

  defp config(provider) do
    Application.get_env(:nimble, :strategies)[provider]
  end
end
