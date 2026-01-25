package haxe;

/**
 * haxe.Exception (Elixir target)
 *
 * WHAT
 * - Concrete `haxe.Exception` implementation for Haxe→Elixir builds.
 *
 * WHY
 * - The upstream Haxe stdlib declares `haxe.Exception` as `extern`, which means it does not emit
 *   any runtime module for Reflaxe targets.
 * - Reflaxe.Elixir compiles Haxe exceptions to Elixir exception structs and relies on a stable
 *   base module for inheritance lowering (`super(...)` → parent `new/...` calls).
 * - We must not generate calls to Elixir's core `Exception` module (it does not provide `new/...`).
 *
 * HOW
 * - Compile `haxe.Exception` to a safe, non-conflicting Elixir module name via `@:native`:
 *   `Reflaxe.Exception`.
 * - Store exception data on the exception struct itself (`message`, `previous`, `native`, `stack`).
 * - Provide `new/1..3` wrappers so optional args behave like Haxe constructors.
 *
 * EXAMPLES
 * Haxe:
 *   throw new haxe.Exception("oops");
 * Elixir (shape):
 *   raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("oops")]
 */
@:coreApi
#if elixir_output
@:native("Reflaxe.Exception")
class Exception {
    /**
     * Exception message.
     */
    public var message(get, never): String;
    private function get_message(): String {
        return untyped __elixir__('Map.get({0}, :message)', this);
    }

    /**
     * The call stack at the moment of the exception creation.
     *
     * NOTE: We currently store stack as an opaque value (default `[]`) to keep the
     * shape stable without depending on `haxe.NativeStackTrace` parity yet.
     */
    public var stack(get, never): CallStack;
    private function get_stack(): CallStack {
        return cast untyped __elixir__('Map.get({0}, :stack, [])', this);
    }

    /**
     * Contains an exception, which was passed to `previous` constructor argument.
     */
    public var previous(get, never): Null<Exception>;
    private function get_previous(): Null<Exception> {
        return cast untyped __elixir__('Map.get({0}, :previous)', this);
    }

    /**
     * Native exception, which caused this exception.
     */
    public var native(get, never): Any;
    public function get_native(): Any {
        return untyped __elixir__('Map.get({0}, :native)', this);
    }

    /**
     * Used internally for wildcard catches like `catch(e:Exception)`.
     *
     * For this target, we treat the caught value as an exception if it is a struct
     * and otherwise wrap it in a `haxe.Exception`.
     */
    static private function caught(value: Any): Exception {
        return if (Std.isOfType(value, Exception)) {
            cast value;
        } else {
            new Exception(Std.string(value), null, value);
        }
    }

    /**
     * Used internally for wrapping non-throwable values for `throw` expressions.
     *
     * For this target, we preserve native exceptions and otherwise return the value.
     */
    static private function thrown(value: Any): Any {
        return if (Std.isOfType(value, Exception)) {
            var exception: Exception = cast value;
            var nativeException = exception.native;
            nativeException != null ? nativeException : exception;
        } else {
            value;
        }
    }

    public function new(message: String, ?previous: Exception, ?native: Any) {
        // Haxe core type exposes read-only properties (get,never). For the Elixir backend, the
        // constructor lowers to `new/3` and we mutate the constructor-local `struct` variable.
        untyped __elixir__('{0} = %{ {0} | message: {1} }', this, message);
        untyped __elixir__('{0} = %{ {0} | previous: {1} }', this, previous);
        untyped __elixir__('{0} = %{ {0} | native: {1} }', this, native);
        untyped __elixir__('{0} = %{ {0} | stack: [] }', this);
    }

    private function unwrap(): Any {
        var n = native;
        return n != null ? n : this;
    }

    public function toString(): String {
        return message;
    }

    public function details(): String {
        // Avoid generating Haxe loop infrastructure in the always-emitted base exception module.
        return untyped __elixir__('
build = fn build, ex, acc ->
  if Kernel.is_nil(ex) do
    acc
  else
    msg = Kernel.to_string(Map.get(ex, :message))
    prev = Map.get(ex, :previous)
    acc = if acc == "", do: msg, else: acc <> "\\nCaused by: " <> msg
    build.(build, prev, acc)
  end
end
build.(build, {0}, "")
', this);
    }
}
#else
extern class Exception {
    /**
     * Exception message.
     */
    public var message(get, never):String;
    private function get_message():String;

    /**
     * The call stack at the moment of the exception creation.
     */
    public var stack(get, never):CallStack;
    private function get_stack():CallStack;

    /**
     * Contains an exception, which was passed to `previous` constructor argument.
     */
    public var previous(get, never):Null<Exception>;
    private function get_previous():Null<Exception>;

    /**
     * Native exception, which caused this exception.
     */
    public var native(get, never):Any;
    final private function get_native():Any;

    /**
     * Used internally for wildcard catches like `catch(e:Exception)`.
     */
    static private function caught(value:Any):Exception;

    /**
     * Used internally for wrapping non-throwable values for `throw` expressions.
     */
    static private function thrown(value:Any):Any;

    public function new(message:String, ?previous:Exception, ?native:Any):Void;
    private function unwrap():Any;
    public function toString():String;
    public function details():String;
}
#end
