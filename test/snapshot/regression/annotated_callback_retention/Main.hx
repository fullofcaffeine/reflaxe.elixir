package;

/**
 * Regression: under `-dce full`, framework-annotated modules must still emit required callbacks.
 *
 * This snapshot relies on RepoDiscovery + AnnotatedModuleEnumerator (via CompilerInit) to:
 * - Force-type `@:application` / `@:supervisor` modules even if they are not referenced by Haxe code.
 * - Preserve their OTP callbacks (start/2, child_spec/1, etc.) so they are emitted in generated Elixir.
 */
class Main {
    static function main() {}
}

