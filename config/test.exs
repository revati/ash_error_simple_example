import Config

config :logger, level: :warning
config :ash, disable_async?: true

config :helpdesk, Helpdesk.Repo,
  username: "postgres",
  password: "secret",
  hostname: "localhost",
  database: "helpdesk_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
