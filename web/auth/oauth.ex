defmodule Nimble.Auth.OAuth do
  @moduledoc false
  alias Assent.Config
  alias Nimble.User

  @spec request(String.t()) :: {:ok, %{url: String.t(), session_params: map}} | {:not_found, String.t()}
  def request(provider) do
    if config = config(provider) do
      config = Config.put(config, :redirect_uri, build_uri(provider))
      config[:strategy].authorize_url(config)
    else
      {:not_found, "No provider configuration for #{provider}"}
    end
  end

  @spec callback(String.t(), map, map) :: {:ok, %{user: User.t(), token: String.t()}} | {:not_found, String.t()}
  def callback(provider, params, session_params \\ %{}) do
    if config = config(provider) do
      config =
        config
        |> Config.put(:session_params, session_params)
        |> Config.put(:redirect_uri, build_uri(provider))

      config[:strategy].callback(config, params)
    else
      {:not_found, "Invalid callback"}
    end
  end

  @spec config(String.t()) :: list | nil
  defp config(provider) do
    Application.get_env(:nimble, :strategies)[String.to_existing_atom(provider)]
  rescue
    ArgumentError ->
      nil
  end

  defp build_uri(provider) do
    "#{Nimble.Endpoint.url()}/api/account/#{provider}/callback"
  end
end
