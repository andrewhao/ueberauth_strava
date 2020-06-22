defmodule Ueberauth.Strategy.Strava.OAuth do
  @moduledoc """
  OAuth2 for Strava.

  Add `client_id` and `client_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Strava.OAuth,
    client_id: System.get_env("Strava_APP_ID"),
    client_secret: System.get_env("Strava_APP_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://www.strava.com/",
    authorize_url: "https://www.strava.com/oauth/authorize",
    token_url: "https://www.strava.com/oauth/token"
  ]

  @doc """
  Construct a client for requests to Strava.

  This will be setup automatically for you in `Ueberauth.Strategy.Strava`.
  These options are only useful for usage outside the normal callback phase
  of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Strava.OAuth)

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    client(token: token)
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.get_token!(token_params(params))
  end

  def token_params(params \\ []) do
    Application.get_env(:ueberauth, Ueberauth.Strategy.Strava.OAuth)
    |> Keyword.take([:client_id, :client_secret])
    |> Keyword.merge(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
