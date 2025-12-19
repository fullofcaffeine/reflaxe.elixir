package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * RepoEnumerator
 *
 * WHAT
 * - Global build macro that marks @:repo externs as kept so Haxe DCE does not eliminate
 *   them when unused directly in user code.
 *
 * WHY
 * - Ecto Repo modules must exist at runtime to satisfy supervision trees and configuration.
 *   Scheduling them for normal compilation (repoTransformPass) requires that the typed class
 *   remains available post-DCE. Adding @:keep at build-time ensures this deterministically.
 *
 * HOW
 * - Attached via Compiler.addGlobalMetadata("", "@:build(...)") in CompilerInit.Start().
 * - For each class, if it carries @:repo, add @:keep (and @:used for good measure) so it
 *   is preserved and passed to the Elixir compiler. No code generation occurs here.
 */
class RepoEnumerator {
    public static function ensureRepoKept(): Null<Array<Field>> {
        #if eval
        final clsRef = Context.getLocalClass();
        if (clsRef != null) {
            final cls = clsRef.get();
            final meta = cls.meta;
            if (meta != null && meta.has(":repo")) {
                // Debug: indicate detection of a @:repo class
                #if eval
                try Context.warning('[RepoEnumerator] Keeping @:repo class: ' + cls.module + '.' + cls.name, cls.pos) catch (_) {}
                #end
                // Ensure the class is preserved by Haxe DCE
                meta.add(":keep", [], cls.pos);
                // Hint that it's intentionally used (helps some tools/pipelines)
                if (!meta.has(":used")) meta.add(":used", [], cls.pos);
            }
        }
        #end
        return null;
    }
}

#end
