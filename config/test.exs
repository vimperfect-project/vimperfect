import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :vimperfect, Vimperfect.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "vimperfect_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :vimperfect, VimperfectWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VNGd5/bfUWdQkjakhnwi9aT/bWL2P7+IfMCeTIHUpQW79osfFs2zoZafqQkzH4df",
  server: false

priv_dir = "test/priv/ssh" |> Path.expand()
# Same as server, we don't enable the ssh server for playground
config :vimperfect, Vimperfect.Playground,
  # server_enable: false,
  ssh_system_dir: priv_dir,
  sessions_dir: "/tmp/vimperfect-sessions",
  ssh_port: 2222,
  handler: Vimperfect.Playground.SessionHandler

# In test we don't send emails
config :vimperfect, Vimperfect.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :error

config :logger, :console,
  format: "[$level] $message | $metadata\n",
  metadata: [:request_id, :addr, :conn, :chan, :mfa]

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
