defmodule Ueberauth.Strategy.Strava do
  @moduledoc """
  Strava Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "public",
    send_redirect_uri: true,
    oauth2_module: Ueberauth.Strategy.Strava.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Strava authentication.
  """
  def handle_request!(conn) do
    opts =
      []
      |> with_scopes(conn)
      |> with_state_param(conn)
      |> with_redirect_uri(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Strava.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = [redirect_uri: callback_url(conn)]

    try do
      client = Ueberauth.Strategy.Strava.OAuth.get_token!([code: code], opts)
      token = client.token

      if token.access_token == nil do
        err = token.other_params["error"]
        desc = token.other_params["error_description"]
        set_errors!(conn, [error(err, desc)])
      else
        fetch_athlete(conn, token)
      end
    rescue
      OAuth2.Error ->
        set_errors!(conn, [error("invalid_code", "The code has been used or has expired")])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:strava_athlete, nil)
    |> put_private(:strava_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    conn.private
    |> Map.fetch!(:strava_athlete)
    |> Map.fetch!("id")
    |> to_string
  end

  @doc """
  Includes the credentials from the Strava response.
  """
  def credentials(conn) do
    token = conn.private.strava_token
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the
  `Ueberauth.Auth` struct.
  """
  def info(conn) do
    athlete = conn.private.strava_athlete

    %Info{
      first_name: athlete["firstname"],
      last_name: athlete["lastname"],
      email: athlete["email"],
      image: athlete["profile"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from
  the Strava callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.strava_token,
        athlete: conn.private.strava_athlete
      }
    }
  end

  defp fetch_athlete(conn, token) do
    conn = put_private(conn, :strava_token, token)
    path = "/api/v3/athlete"

    case Ueberauth.Strategy.Strava.OAuth.get(token, path) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: athlete}}
      when status_code in 200..399 ->
        put_private(conn, :strava_athlete, athlete)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end

  defp with_scopes(opts, conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    opts |> Keyword.put(:scope, scopes)
  end

  defp with_redirect_uri(opts, conn) do
    if option(conn, :send_redirect_uri) do
      opts |> Keyword.put(:redirect_uri, callback_url(conn))
    else
      opts
    end
  end
end
