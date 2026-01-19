package reflaxe.elixir.runtime;

/**
 * ReflaxeException
 *
 * WHAT
 * - A concrete Elixir exception module (`Reflaxe.Exception`) used as the base for Haxe exception
 *   constructor lowering.
 *
 * WHY
 * - Haxe's `haxe.Exception` is `extern` in the official stdlib for many targets, so it does not emit
 *   a runtime module for the Elixir output.
 * - Reflaxe.Elixir lowers `super(...)` constructor calls into `ParentModule.new/arity` calls. For
 *   exception subclasses, we must not generate calls to the Elixir core `Exception` module (which
 *   doesn't provide `new/1..3`), and we also want to avoid naming collisions by emitting a stable
 *   `Reflaxe.Exception` module.
 * - The Todo app and snapshot suite run with `--warnings-as-errors`; missing exception base modules
 *   become build failures.
 *
 * HOW
 * - This module is always included for Elixir builds (via `CompilerInit`), and provides:
 *   - `defexception [:message, :previous, :native]` (via the compiler's exception-module printer)
 *   - `new/3` for constructor lowering paths.
 */
@:native("Reflaxe.Exception")
class ReflaxeException {
    public var message: String;
    public var previous: Null<haxe.Exception>;
    public var native: Any;

    public function new(message: String, ?previous: haxe.Exception, ?native: Any) {
        this.message = message;
        this.previous = previous;
        this.native = native;
    }

    public function toString(): String {
        return message;
    }
}

