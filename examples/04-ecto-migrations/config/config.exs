import Config

config :ecto_migrations_example,
  ecto_repos: [EctoMigrationsExample.Repo]

config :ecto_migrations_example, EctoMigrationsExample.Repo,
  username: System.get_env("ECTO_MIGRATIONS_DB_USER", "postgres"),
  password: System.get_env("ECTO_MIGRATIONS_DB_PASSWORD", "postgres"),
  hostname: System.get_env("ECTO_MIGRATIONS_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("ECTO_MIGRATIONS_DB_PORT", "5432")),
  database: System.get_env("ECTO_MIGRATIONS_DATABASE", "ecto_migrations_example_dev"),
  pool_size: 2

config :logger, level: :warning
