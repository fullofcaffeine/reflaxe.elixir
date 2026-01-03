package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Atom;
import elixir.types.Term;

/**
 * Ecto Migrator
 *
 * WHAT
 * - Minimal extern for `Ecto.Migrator` needed to run migrations programmatically.
 *
 * WHY
 * - Enables app-level tooling (examples, releases) to keep schemas in sync without
 *   shelling out to Mix or using raw `__elixir__()` injection.
 *
 * HOW
 * - Maps directly to Elixir's `Ecto.Migrator.with_repo/2-3` and `Ecto.Migrator.run/4`.
 *
 * EXAMPLES
 * Haxe:
 *   var opts = [{_0: "all", _1: true}];
 *   Migrator.withRepo(repo, repo -> Migrator.run(repo, "priv/repo/migrations", "up", opts));
 *
 * Elixir:
 *   Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
 *     Ecto.Migrator.run(repo, "priv/repo/migrations", :up, all: true)
 *   end)
 */
@:native("Ecto.Migrator")
extern class Migrator {
    @:native("with_repo")
    @:overload(function(repo: Term, callback: Term -> Term): Term {})
    static function withRepo(repo: Term, callback: Term -> Term, opts: Array<{_0: Atom, _1: Term}>): Term;

    @:native("run")
    static function run(repo: Term, path: String, direction: Atom, opts: Array<{_0: Atom, _1: Term}>): Term;
}

#end
