import Config

require Logger

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/fixedgear start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :fixedgear, FixedGearWeb.Endpoint, server: true
end

config :fixedgear, stage: System.fetch_env!("STAGE")

if config_env() == :prod do
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  host = System.fetch_env!("PHX_HOST")
  port = String.to_integer(System.get_env("PORT", "443"))

  case System.get_env("STAGE") do
    stage when stage in ["local", "dev", "staging", "prod"] ->
      :ok =
        Logger.warning(
          "Ignoring variable DATABASE_URL as Postgrex connection protocol, " <>
            "proceeding with direct TCP connection."
        )

      config :fixedgear, FixedGear.Repo,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
        socket_options: maybe_ipv6,
        show_sensitive_data_on_connection_error: false,
        database: System.get_env("DB_DATABASE"),
        username: System.fetch_env!("DB_USERNAME"),
        password: System.fetch_env!("DB_PASSWORD"),
        hostname: System.fetch_env!("DB_HOSTNAME")

      config :fixedgear, FixedGearWeb.Endpoint,
        http: [port: port, ip: {0, 0, 0, 0, 0, 0, 0, 0}],
        url: [host: host, port: 80]

    _stage ->
      :ok = Logger.info("Using DATABASE_URL as Postgrex connection protocol.")

      database_url =
        System.get_env("DATABASE_URL") ||
          raise """
          environment variable DATABASE_URL is missing.
          For example: ecto://USER:PASS@HOST/DATABASE
          """

      config :fixedgear, FixedGear.Repo,
        ssl: true,
        url: database_url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
        socket_options: maybe_ipv6

      config :fixedgear, FixedGearWeb.Endpoint,
        http: [port: port, ip: {0, 0, 0, 0, 0, 0, 0, 0}],
        url: [scheme: "https", host: host, port: port]
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :fixedgear, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :fixedgear, FixedGearWeb.Endpoint,
    server: true,
    secret_key_base: secret_key_base

  # ----------------------------------------------------------------------------
  # Email configuration
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for SendGrid:
  #
  #     config :fixedgear, FixedGear.Mailer,
  #       adapter: Swoosh.Adapters.Sendgrid,
  #       api_key: System.get_env("SENDGRID_API_KEY")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req out-of-the-box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :fixedgear, from_email: System.fetch_env!("FIXEDGEAR_FROM_EMAIL")

  config :fixedgear, FixedGear.Mailer, api_key: System.fetch_env!("SENDGRID_API_KEY")
end
