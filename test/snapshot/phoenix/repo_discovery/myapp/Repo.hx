package myapp;

import ecto.DatabaseAdapter.*;

/**
 * Unreferenced repo extern used to validate RepoDiscovery behavior.
 *
 * This file intentionally is *not* referenced from Main.hx; RepoDiscovery must
 * force typing it so the @:repo transform can emit the Elixir module.
 */
@:native("MyApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason,
    extensions: [],
    poolSize: 10
})
extern class Repo {}

