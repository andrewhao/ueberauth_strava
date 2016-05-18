# Überauth Strava
[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/andrewhao/ueberauth_strava.png?branch=master
[travis]: https://travis-ci.org/andrewhao/ueberauth_strava
[hex-img]: https://img.shields.io/hexpm/v/ueberauth_strava.svg
[hex]: https://hex.pm/packages/ueberauth_strava
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> Strava OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Strava Developers](https://www.strava.com/settings/api).

1. Add `:ueberauth_strava` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_strava, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_strava]]
    end
    ```

1. Add Strava to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        Strava: {Ueberauth.Strategy.Strava, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Strava.OAuth,
      client_id: System.get_env("STRAVA_CLIENT_ID"),
      client_secret: System.get_env("STRAVA_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/strava

Or with options:

    /auth/strava?scope=view_private,write

By default the requested scope is "public". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    Strava: {Ueberauth.Strategy.Strava, [default_scope: "view_private,write"]}
  ]
```

See [Strava API Access Documentation](http://strava.github.io/api/#access) for full API references.

## License

Please see [LICENSE](https://github.com/andrewhao/ueberauth_strava/blob/master/LICENSE) for licensing details.

