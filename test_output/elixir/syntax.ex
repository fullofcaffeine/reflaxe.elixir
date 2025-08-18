defmodule Syntax do
  @moduledoc """
    Syntax module generated from Haxe

     * Generate Elixir syntax not directly supported by Haxe.
     * Use only at low-level when specific target-specific code-generation is required.
     *
     * This is the type-safe alternative to `untyped __elixir__()` calls.
     * Provides compile-time validation and IDE support while maintaining
     * the same functionality as the underlying injection mechanism.
     *
     * ## Critical: Macro-Time vs Runtime Processing
     *
     * **IMPORTANT**: These methods are designed for **macro-time processing** by the
     * Reflaxe.Elixir compiler, NOT for runtime execution:
     *
     * - **Macro-Time**: When `haxe build.hxml` runs, the compiler transforms these calls to raw Elixir code
     * - **Test-Time**: With `-D reflaxe_runtime`, compiler classes become available for testing but shouldn't execute
     * - **True Runtime**: In the BEAM VM, these calls should never exist - they're replaced with generated Elixir
     *
     * The `#if (elixir || reflaxe_runtime)` guards ensure these are only available in appropriate contexts.
     *
     * ## Usage Examples
     *
     * ```haxe
     * // Basic code injection
     * var result = elixir.Syntax.code("DateTime.utc_now()");
     *
     * // Code injection with parameters
     * var formatted = elixir.Syntax.code("String.slice({0}, {1}, {2})", str, start, length);
     *
     * // Create atoms
     * var atom = elixir.Syntax.atom("ok");
     *
     * // Create tuples
     * var tuple = elixir.Syntax.tuple("ok", result);
     * ```
     *
     * ## Compilation Process
     *
     * 1. **Haxe Parsing**: Methods provide valid syntax for Haxe type checking
     * 2. **Compiler Processing**: Reflaxe.Elixir transforms calls to injection at macro-time
     * 3. **Code Generation**: Raw Elixir code replaces the method calls in output
     * 4. **Runtime**: No trace of these methods exists in final BEAM bytecode
     *
     * @see documentation/ELIXIR_INJECTION_GUIDE.md - Complete injection guide
     * @see js.Syntax - Similar pattern for JavaScript target in Haxe 4.1+
  """

  # Static functions
  @doc """
    Inject `code` directly into generated Elixir source.

    `code` must be a string constant.

    Additional `args` are supported to provide code interpolation:
    ```haxe
    elixir.Syntax.code("IO.puts({0})", "Hello World");
    ```
    will generate
    ```elixir
    IO.puts("Hello World")
    ```

    Emits a compilation error if the count of `args` does not match
    the count of placeholders in `code`.

    @param code Elixir code string with {N} placeholders
    @param args Arguments to interpolate into the code string
    @return Dynamic result (typed as needed by context)
  """
  @spec code(String.t(), Rest.t()) :: term()
  def code(code, args) do
    temp_rest = nil
    this = nil
    this = [args]
    temp_rest = this
    Injection.__elixir__(code, temp_rest)
  end

  @doc """
    Inject `code` directly into generated Elixir source.
    The same as `elixir.Syntax.code` except this one does not provide code interpolation.

    @param code Raw Elixir code string
    @return Dynamic result (typed as needed by context)
  """
  @spec plain_code(String.t()) :: term()
  def plain_code(code) do
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__(code, temp_rest)
  end

  @doc """
    Generate an Elixir atom.

    ```haxe
    var success = elixir.Syntax.atom("ok");
    ```
    generates
    ```elixir
    :ok
    ```

    @param name Atom name (without the colon)
    @return Dynamic atom value
  """
  @spec atom(String.t()) :: term()
  def atom(name) do
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__(":" <> name, temp_rest)
  end

  @doc """
    Generate an Elixir tuple.

    ```haxe
    var result = elixir.Syntax.tuple("ok", value, 42);
    ```
    generates
    ```elixir
    {:ok, value, 42}
    ```

    @param args Tuple elements
    @return Dynamic tuple value
  """
  @spec tuple(Rest.t()) :: term()
  def tuple(args) do
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__("{" <> Enum.join(args.copy(), ", ") <> "}", temp_rest)
  end

  @doc """
    Generate an Elixir keyword list.

    ```haxe
    var opts = elixir.Syntax.keyword(["name", "John", "age", 30]);
    ```
    generates
    ```elixir
    [name: "John", age: 30]
    ```

    @param pairs Array of alternating keys and values
    @return Dynamic keyword list
  """
  @spec keyword(Array.t()) :: term()
  def keyword(pairs) do
    keyword_pairs = []
    i = 0
    (
      try do
        loop_fn = fn {i} ->
          if (i < length(pairs)) do
            try do
              keyword_pairs ++ ["" <> Std.string(Enum.at(pairs, i)) <> ": " <> Std.string(Enum.at(pairs, i + 1))]
          # i updated with + 2
          loop_fn.({i + 2})
            catch
              :break -> {i}
              :continue -> loop_fn.({i})
            end
          else
            {i}
          end
        end
        loop_fn.({i})
      catch
        :break -> {i}
      end
    )
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__("[" <> Enum.join(keyword_pairs, ", ") <> "]", temp_rest)
  end

  @doc """
    Generate an Elixir map.

    ```haxe
    var map = elixir.Syntax.map(["key1", "value1", "key2", "value2"]);
    ```
    generates
    ```elixir
    %{"key1" => "value1", "key2" => "value2"}
    ```

    @param pairs Array of alternating keys and values
    @return Dynamic map value
  """
  @spec map(Array.t()) :: term()
  def map(pairs) do
    map_pairs = []
    i = 0
    (
      try do
        loop_fn = fn {i} ->
          if (i < length(pairs)) do
            try do
              map_pairs ++ ["" <> Std.string(Enum.at(pairs, i)) <> " => " <> Std.string(Enum.at(pairs, i + 1))]
          # i updated with + 2
          loop_fn.({i + 2})
            catch
              :break -> {i}
              :continue -> loop_fn.({i})
            end
          else
            {i}
          end
        end
        loop_fn.({i})
      catch
        :break -> {i}
      end
    )
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__("%{" <> Enum.join(map_pairs, ", ") <> "}", temp_rest)
  end

  @doc """
    Generate an Elixir pipe operation.

    ```haxe
    var result = elixir.Syntax.pipe(data, "Enum.map(&transform/1)", "Enum.filter(&valid?/1)");
    ```
    generates
    ```elixir
    data |> Enum.map(&transform/1) |> Enum.filter(&valid?/1)
    ```

    @param initial Initial value to pipe
    @param operations Pipeline operations
    @return Dynamic result of pipeline
  """
  @spec pipe(term(), Rest.t()) :: term()
  def pipe(initial, operations) do
    pipeline = "" <> Std.string(initial) <> " |> " <> Enum.join(operations.copy(), " |> ")
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__(pipeline, temp_rest)
  end

  @doc """
    Generate pattern matching expression.

    ```haxe
    var result = elixir.Syntax.match(value, '{:ok, result} -> result\n{:error, _} -> nil');
    ```
    generates
    ```elixir
    case value do
      {:ok, result} -> result
      {:error, _} -> nil
    end
    ```

    @param value Value to match against
    @param patterns Pattern matching cases (newline separated)
    @return Dynamic result of pattern match
  """
  @spec match(term(), String.t()) :: term()
  def match(value, patterns) do
    pattern_lines = Enum.join(String.split(patterns, "\n"), "\n  ")
    temp_rest = nil
    this = nil
    this = []
    temp_rest = this
    Injection.__elixir__("case " <> Std.string(value) <> " do\n  " <> pattern_lines <> "\nend", temp_rest)
  end

end
