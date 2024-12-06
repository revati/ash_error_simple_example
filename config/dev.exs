import Config

config :helpdesk, Helpdesk.Repo,
  username: "postgres",
  password: "secret",
  hostname: "localhost",
  database: "helpdesk_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
