package;

import ecto.DatabaseAdapter.*;

/**
 * Minimal Ecto repository used by the executable migration example.
 *
 * The generated Elixir is the ordinary target primitive:
 * `use Ecto.Repo, otp_app: :ecto_migrations_example, adapter: Ecto.Adapters.Postgres`.
 */
@:native("EctoMigrationsExample.Repo")
@:repo({
	adapter: Postgres,
	json: Jason,
	extensions: [],
	poolSize: 2
})
extern class Repo {}
