defmodule Nimble.Auth.OIDProvider do
  def request(provider) do
    config =
      config!(provider)
      |> Assent.Config.put(:redirect_uri, "http://localhost:4000/auth/callback")

    config[:strategy].authorize_url(config)
  end

  def callback(provider, params, session_params \\ %{}) do
    config =
      provider
      |> config!()
      |> Assent.Config.put(:session_params, session_params)

    config[:strategy].callback(config, params)
  end

  defp config!(provider) do
    Application.get_env(:nimble, :strategies)[provider] ||
      raise "No provider configuration for #{provider}"
  end
end
