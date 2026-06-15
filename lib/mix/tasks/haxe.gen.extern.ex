defmodule Mix.Tasks.Haxe.Gen.Extern do
  @moduledoc """
  Generates a starter Haxe `extern` from an Elixir module.

  This is intended to help you integrate existing Elixir/Erlang libraries from Haxe
  without reaching for `untyped __elixir__(...)` in application code.

  The generated extern uses `elixir.types.Term` at the boundary by default (safe, but generic).
  You can then tighten types incrementally and decode dynamic returns with `elixir.types.TermDecoder`.

  ## Examples

      mix haxe.gen.extern Enum
      mix haxe.gen.extern Ecto.Changeset --package externs.ecto --out src_haxe/externs
      mix haxe.gen.extern :crypto --package externs.erlang --out src_haxe/externs
      mix haxe.gen.extern Jason --wrapper --decoder --test-pointer
      mix haxe.gen.extern MyApp.PubSub --boundary --package my_app.infrastructure --out src_haxe

  ## Options

    * `--out` - Output directory (default: `src_haxe/externs`)
    * `--package` - Haxe package name (default: `externs`)
    * `--class-name` - Override generated Haxe class name (default: last segment of module)
    * `--boundary` - Generate a minimal app-local module reference extern without loading the module
    * `--wrapper` - Also generate a normal Haxe wrapper class for app-facing calls
    * `--decoder` - Also generate a `TermDecoder` helper template
    * `--test-pointer` - Also generate a minimal Haxe ExUnit test scaffold pointer

  """

  use Mix.Task

  @shortdoc "Generate a starter Haxe extern from an Elixir module"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _} =
      OptionParser.parse(args,
        switches: [
          out: :string,
          package: :string,
          class_name: :string,
          boundary: :boolean,
          wrapper: :boolean,
          decoder: :boolean,
          test_pointer: :boolean
        ]
      )

    case argv do
      [module_name | _] ->
        generate(module_name, opts)

      _ ->
        Mix.shell().error("""
        Expected a module name.

        Usage:
          mix haxe.gen.extern Module.Name [--out DIR] [--package PKG] [--class-name Name]
          mix haxe.gen.extern Module.Name --boundary
          mix haxe.gen.extern Module.Name --wrapper --decoder --test-pointer
        """)

        System.halt(1)
    end
  end

  defp generate(module_name, opts) when is_binary(module_name) do
    native_module = String.trim(module_name)
    module = parse_module(native_module)
    boundary? = Keyword.get(opts, :boundary, false)

    unless boundary? or Code.ensure_loaded?(module) do
      Mix.shell().error("Module not available: #{native_module}")
      System.halt(1)
    end

    out_dir = Keyword.get(opts, :out, "src_haxe/externs")
    pkg = Keyword.get(opts, :package, "externs") |> normalize_package()
    class_name = Keyword.get(opts, :class_name, default_class_name(native_module))
    package_dir = package_output_dir(out_dir, pkg)

    functions = if boundary?, do: %{}, else: exported_functions(module)

    File.mkdir_p!(package_dir)

    file_path = Path.join(package_dir, "#{class_name}.hx")

    File.write!(
      file_path,
      render_extern_haxe(pkg, class_name, native_module, functions, boundary?)
    )

    Mix.shell().info("Generated extern: #{file_path}")

    if Keyword.get(opts, :wrapper, false) and not boundary? do
      wrapper_class_name = "#{class_name}Wrapper"
      wrapper_path = Path.join(package_dir, "#{wrapper_class_name}.hx")

      File.write!(
        wrapper_path,
        render_wrapper_haxe(pkg, class_name, wrapper_class_name, functions)
      )

      Mix.shell().info("Generated wrapper: #{wrapper_path}")
    end

    if Keyword.get(opts, :decoder, false) and not boundary? do
      decoder_class_name = "#{class_name}Decoder"
      decoder_path = Path.join(package_dir, "#{decoder_class_name}.hx")

      File.write!(decoder_path, render_decoder_haxe(pkg, decoder_class_name, class_name))

      Mix.shell().info("Generated decoder template: #{decoder_path}")
    end

    if boundary? and (Keyword.get(opts, :wrapper, false) or Keyword.get(opts, :decoder, false)) do
      Mix.shell().info(
        "Skipped wrapper/decoder: --boundary externs intentionally have no callable surface."
      )
    end

    if Keyword.get(opts, :test_pointer, false) do
      test_pointer_path = Path.join(package_dir, "#{class_name}InteropTest.md")

      File.write!(test_pointer_path, render_test_pointer(pkg, class_name))

      Mix.shell().info("Generated test pointer: #{test_pointer_path}")
    end
  end

  defp exported_functions(module) do
    module
    |> module_exports()
    |> Enum.map(fn {name, arity} -> {Atom.to_string(name), arity} end)
    |> Enum.sort_by(fn {name, arity} -> {name, arity} end)
    |> Enum.group_by(fn {name, _arity} -> name end, fn {_name, arity} -> arity end)
  end

  defp module_exports(module) do
    if function_exported?(module, :__info__, 1) do
      module.__info__(:functions)
    else
      module.module_info(:exports)
      |> Enum.reject(fn {name, _arity} -> name in [:module_info, :behaviour_info] end)
    end
  end

  defp parse_module(":" <> erlang_module) do
    String.to_atom(erlang_module)
  end

  defp parse_module(elixir_module) do
    parts = String.split(elixir_module, ".", trim: true)
    Module.concat(parts)
  end

  defp default_class_name(":" <> rest) do
    rest |> Macro.camelize()
  end

  defp default_class_name(module_name) do
    module_name |> String.split(".", trim: true) |> List.last() |> to_string()
  end

  defp normalize_package(pkg) do
    pkg
    |> String.trim()
    |> String.split(".", trim: true)
    |> Enum.map(&String.downcase/1)
    |> Enum.join(".")
  end

  defp package_output_dir(out_dir, pkg) do
    package_parts = String.split(pkg, ".", trim: true)
    out_parts = Path.split(out_dir)
    matched_parts = longest_package_prefix_in_path_suffix(out_parts, package_parts)
    remaining_parts = Enum.drop(package_parts, matched_parts)

    Path.join([out_dir | remaining_parts])
  end

  defp longest_package_prefix_in_path_suffix(_out_parts, []), do: 0

  defp longest_package_prefix_in_path_suffix(out_parts, package_parts) do
    max_match = min(length(out_parts), length(package_parts))

    max_match..0//-1
    |> Enum.find(0, fn match_length ->
      match_length == 0 ||
        Enum.take(out_parts, -match_length) == Enum.take(package_parts, match_length)
    end)
  end

  defp render_extern_haxe(pkg, class_name, native_module, functions_by_name, boundary?) do
    if boundary? do
      render_boundary_extern_haxe(pkg, class_name, native_module)
    else
      render_callable_extern_haxe(pkg, class_name, native_module, functions_by_name)
    end
  end

  defp render_boundary_extern_haxe(pkg, class_name, native_module) do
    """
    // Generated by `mix haxe.gen.extern --boundary`
    // Native module reference: #{native_module}
    // Canonical workflow: docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md

    package #{pkg};

    @:native("#{native_module}")
    @:unsafeExtern
    extern class #{class_name} {}
    """
  end

  defp render_callable_extern_haxe(pkg, class_name, native_module, functions_by_name) do
    header = """
    // Generated by `mix haxe.gen.extern`
    // Native module: #{native_module}
    // Canonical workflow: docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md

    package #{pkg};

    import elixir.types.Term;

    @:native("#{native_module}")
    @:unsafeExtern
    extern class #{class_name} {

    """

    body =
      functions_by_name
      |> Enum.map(fn {name, arities} -> render_function_group(name, arities) end)
      |> Enum.join("\n")

    footer = """
    }
    """

    header <> body <> footer
  end

  defp render_wrapper_haxe(pkg, extern_class_name, wrapper_class_name, functions_by_name) do
    body =
      functions_by_name
      |> Enum.map(fn {name, arities} ->
        render_wrapper_function(name, arities, extern_class_name)
      end)
      |> Enum.join("\n")

    """
    // Generated by `mix haxe.gen.extern --wrapper`
    // Canonical workflow: docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md

    package #{pkg};

    import elixir.types.Term;

    /**
     * App-facing wrapper over #{extern_class_name}.
     *
     * Keep this class small: refine parameter and return types here as the native
     * boundary becomes clearer, while leaving #{extern_class_name} API-faithful.
     */
    class #{wrapper_class_name} {
    #{body}}
    """
  end

  defp render_wrapper_function(native_name, arities, extern_class_name) do
    arity = Enum.max(arities)
    haxe_name = haxe_function_name(native_name)
    params = render_params(arity)
    args = render_args(arity)

    if length(arities) > 1 do
      """
        // #{extern_class_name}.#{haxe_name} also supports arities: #{arity_list(arities)}.
        public static function #{haxe_name}(#{params}): Term {
          return #{extern_class_name}.#{haxe_name}(#{args});
        }
      """
    else
      """
        public static function #{haxe_name}(#{params}): Term {
          return #{extern_class_name}.#{haxe_name}(#{args});
        }
      """
    end
  end

  defp render_decoder_haxe(pkg, decoder_class_name, extern_class_name) do
    """
    // Generated by `mix haxe.gen.extern --decoder`
    // Canonical workflow: docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md

    package #{pkg};

    import elixir.types.Term;
    import elixir.types.TermDecoder;
    import elixir.types.TermDecoder.TermDecodeError;
    import haxe.functional.Result;

    /**
     * Decoder helpers for #{extern_class_name} wrapper boundaries.
     *
     * Add app-specific decoders here as you replace generic Term values with
     * stable Haxe typedefs, enums, and Result shapes.
     */
    class #{decoder_class_name} {
      public static function asString(term: Term): Result<String, TermDecodeError> {
        return TermDecoder.asString(term);
      }

      public static function asInt(term: Term): Result<Int, TermDecodeError> {
        return TermDecoder.asInt(term);
      }

      public static function asBool(term: Term): Result<Bool, TermDecodeError> {
        return TermDecoder.asBool(term);
      }

      public static function asTermList(term: Term): Result<Array<Term>, TermDecodeError> {
        return TermDecoder.asList(term);
      }
    }
    """
  end

  defp render_test_pointer(pkg, class_name) do
    """
    # #{class_name} Interop Test Pointer

    Generated by `mix haxe.gen.extern --test-pointer`.

    Recommended location for the first runtime test:

    - `test_haxe/externs/#{class_name}InteropTest.hx`

    Reference docs:

    - `docs/02-user-guide/exunit-testing.md`
    - `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`

    Minimal Haxe ExUnit scaffold:

    ```haxe
    package #{pkg};

    import haxe.test.Assert;
    import haxe.test.ExUnit.TestCase;

    @:exunit
    class #{class_name}InteropTest extends TestCase {
      @:test
      public function generatedExternIsReachable():Void {
        Assert.isTrue(true);
      }
    }
    ```
    """
  end

  defp render_function_group(name, arities) do
    arities = Enum.sort(arities)
    haxe_name = haxe_function_name(name)

    case arities do
      [arity] ->
        render_function(name, haxe_name, arity, [])

      _ ->
        max_arity = Enum.max(arities)
        overloads = Enum.filter(arities, &(&1 != max_arity))
        render_function(name, haxe_name, max_arity, overloads)
    end
  end

  defp render_function(native_name, haxe_name, arity, overload_arities) do
    overloads =
      overload_arities
      |> Enum.map(fn overload_arity ->
        """
            @:overload(function(#{render_params(overload_arity)}): Term {})
        """
      end)
      |> Enum.join("")

    """
        #{overloads}    @:native("#{native_name}")
        public static function #{haxe_name}(#{render_params(arity)}): Term;
    """
  end

  defp render_params(0), do: ""

  defp render_params(arity) do
    1..arity
    |> Enum.map(&param_name/1)
    |> Enum.map(fn name -> "#{name}: Term" end)
    |> Enum.join(", ")
  end

  defp render_args(0), do: ""

  defp render_args(arity) do
    1..arity
    |> Enum.map(&param_name/1)
    |> Enum.join(", ")
  end

  defp arity_list(arities) do
    arities
    |> Enum.sort()
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join(", ")
  end

  defp param_name(1), do: "first"
  defp param_name(2), do: "second"
  defp param_name(3), do: "third"
  defp param_name(4), do: "fourth"
  defp param_name(5), do: "fifth"
  defp param_name(6), do: "sixth"
  defp param_name(7), do: "seventh"
  defp param_name(8), do: "eighth"
  defp param_name(9), do: "ninth"
  defp param_name(10), do: "tenth"
  defp param_name(11), do: "eleventh"
  defp param_name(12), do: "twelfth"
  defp param_name(13), do: "thirteenth"
  defp param_name(14), do: "fourteenth"
  defp param_name(15), do: "fifteenth"
  defp param_name(16), do: "sixteenth"
  defp param_name(17), do: "seventeenth"
  defp param_name(18), do: "eighteenth"
  defp param_name(19), do: "nineteenth"
  defp param_name(20), do: "twentieth"

  defp param_name(n) when is_integer(n) and n > 20 do
    # Avoid numeric suffixes in generated Haxe identifiers; fall back to lettered args.
    "arg" <> base26_alpha(n - 21)
  end

  defp base26_alpha(n) when is_integer(n) and n >= 0 do
    # 0 -> A, 25 -> Z, 26 -> AA, ...
    alphabet = ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    to_base26_alpha(n, alphabet, [])
  end

  defp to_base26_alpha(n, alphabet, acc) when n < 26 do
    [Enum.at(alphabet, n) | acc] |> to_string()
  end

  defp to_base26_alpha(n, alphabet, acc) do
    q = div(n, 26) - 1
    r = rem(n, 26)
    to_base26_alpha(q, alphabet, [Enum.at(alphabet, r) | acc])
  end

  defp haxe_function_name(native) do
    {base, suffix} =
      cond do
        String.ends_with?(native, "?") -> {String.trim_trailing(native, "?"), "Q"}
        String.ends_with?(native, "!") -> {String.trim_trailing(native, "!"), "Bang"}
        true -> {native, ""}
      end

    base =
      base
      |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
      |> Macro.camelize()

    name =
      case base do
        "" ->
          "call"

        other ->
          String.replace_prefix(other, String.first(other), String.downcase(String.first(other)))
      end

    sanitize_haxe_ident(name <> suffix)
  end

  defp sanitize_haxe_ident("new"), do: "new_"
  defp sanitize_haxe_ident("function"), do: "function_"
  defp sanitize_haxe_ident("var"), do: "var_"
  defp sanitize_haxe_ident(other), do: other
end
