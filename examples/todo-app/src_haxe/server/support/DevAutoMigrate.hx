package server.support;

import ecto.Migrator;
import elixir.Atom as ErlangAtom;
import elixir.types.Atom;
import elixir.types.Term;

/**
 * DevAutoMigrate
 *
 * WHAT
 * - Runs pending Ecto migrations on boot in dev-like environments.
 *
 * WHY
 * - The todo-app evolves quickly (schemas/migrations). Developers often start it with
 *   `mix phx.server`, which does not run `ecto.migrate`. This keeps the app bootable
 *   even when the local DB was created from an older schema.
 *
 * HOW
 * - Guarded by MIX_ENV (dev|e2e) and TODOAPP_AUTO_MIGRATE (set to "0"/"false"/"no" to disable).
 * - Uses `Ecto.Migrator.with_repo/2` to ensure Repo is started, then runs:
 *     Ecto.Migrator.run(repo, "priv/repo/migrations", :up, all: true)
 *
 * EXAMPLES
 * Haxe:
 *   DevAutoMigrate.runIfEnabled();
 */
class DevAutoMigrate {
    public static function runIfEnabled(): Void {
        var mixEnv = Sys.getEnv("MIX_ENV");
        if (mixEnv != "dev" && mixEnv != "e2e") {
            return;
        }

        var autoMigrateFlag = Sys.getEnv("TODOAPP_AUTO_MIGRATE");
        if (autoMigrateFlag != null) {
            var normalizedFlag = autoMigrateFlag.toLowerCase();
            if (normalizedFlag == "0" || normalizedFlag == "false" || normalizedFlag == "no") {
                return;
            }
        }

        var options: Array<{_0: Atom, _1: Term}> = [{_0: "all", _1: true}];

        var repoModule: Term = ErlangAtom.fromString("Elixir.TodoApp.Repo");

        Migrator.withRepo(repoModule, function(repo: Term): Term {
            return Migrator.run(repo, "priv/repo/migrations", "up", options);
        }, []);
    }
}
