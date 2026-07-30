defmodule Mix.Tasks.Haxe.Gen.ProjectTest do
  use ExUnit.Case, async: true

  @mix_exs_without_test_alias """
  defmodule MyApp.MixProject do
    use Mix.Project

    def project do
      [
        app: :my_app,
        version: "0.1.0",
        elixir: "~> 1.14",
        aliases: aliases(),
        deps: []
      ]
    end

    defp aliases do
      [
        "assets.build": ["esbuild my_app"]
      ]
    end
  end
  """

  @mix_exs_without_aliases """
  defmodule MyApp.MixProject do
    use Mix.Project

    def project do
      [
        app: :my_app,
        version: "0.1.0",
        elixir: "~> 1.14",
        deps: []
      ]
    end
  end
  """

  @mix_exs_with_custom_test_alias """
  defmodule MyApp.MixProject do
    use Mix.Project

    def project do
      [
        app: :my_app,
        aliases: aliases(),
        deps: []
      ]
    end

    defp aliases do
      [
        test: ["ecto.create --quiet", "test"]
      ]
    end
  end
  """

  @mix_exs_with_aliases_arity_one """
  defmodule AliasArityOneProject do
    def project do
      [
        app: :alias_arity_one,
        aliases_arity_one: aliases([])
      ]
    end

    defp aliases(_opts) do
      [
        test: ["test"]
      ]
    end
  end
  """

  @mix_exs_with_commented_haxe_alias """
  defmodule CommentedAliasProject do
    def project do
      [
        app: :commented_alias,
        aliases: aliases()
      ]
    end

    defp aliases do
      [
        # "haxe.compile.tests": ["cmd haxe build-tests.hxml"],
        test: ["test"]
      ]
    end
  end
  """

  @mix_exs_with_custom_compilers """
  defmodule CustomCompilerProject do
    def project do
      [
        app: :custom_compiler,
        compilers: [:custom] ++ Mix.compilers()
      ]
    end
  end
  """

  @mix_exs_with_custom_haxe_compile_tests_alias """
  defmodule CustomHaxeTestAliasProject do
    def project do
      [
        app: :custom_haxe_test_alias,
        aliases: aliases()
      ]
    end

    defp aliases do
      [
        "haxe.compile.tests": ["cmd echo application-owned"]
      ]
    end
  end
  """

  @mix_exs_with_duplicate_haxe_compile_tests_aliases """
  defmodule DuplicateHaxeTestAliasProject do
    def project do
      [
        app: :duplicate_haxe_test_alias,
        aliases: aliases()
      ]
    end

    defp aliases do
      [
        "haxe.compile.tests": ["cmd haxe build-tests.hxml"],
        "haxe.compile.tests": ["cmd haxe build-tests.hxml"]
      ]
    end
  end
  """

  @test_helper_minimal """
  ExUnit.start()
  """

  defp phoenix_config(overrides \\ []) do
    Map.merge(
      %{
        app_name: :my_app,
        haxe_namespace: "my_app_hx",
        elixir_namespace: "MyApp",
        module_name: "MyApp",
        haxe_dir: "src_haxe",
        output_dir: "lib/my_app_hx",
        basic_modules: false,
        phoenix: true,
        live_react: false,
        client_mode: :genes,
        skip_examples: true
      },
      Map.new(overrides)
    )
  end

  test "build.hxml enables strict TSX mode for phoenix scaffolds" do
    config = phoenix_config()
    hxml = Mix.Tasks.Haxe.Gen.Project.build_hxml_content_for_test(config)

    assert hxml =~ "-D hxx_string_to_sigil"
    assert hxml =~ "-D hxx_mode=tsx"
    assert hxml =~ "# -D reflaxe_elixir_format=write"
    refute hxml =~ "-D reflaxe_runtime"
  end

  test "build.hxml does not inject TSX flag for non-phoenix scaffolds" do
    config = phoenix_config(phoenix: false)
    hxml = Mix.Tasks.Haxe.Gen.Project.build_hxml_content_for_test(config)

    refute hxml =~ "-D hxx_string_to_sigil"
    refute hxml =~ "-D hxx_mode=tsx"
    assert hxml =~ "# -D reflaxe_elixir_format=write"
  end

  test "build-tests.hxml includes ExUnit and generated test output wiring" do
    config = phoenix_config()
    test_hxml = Mix.Tasks.Haxe.Gen.Project.build_tests_hxml_content_for_test(config)

    assert test_hxml =~ "-cp src_haxe"
    assert test_hxml =~ "-cp test_haxe"
    assert test_hxml =~ "-D elixir_output=test/generated"
    assert test_hxml =~ "-D elixir_output_exs"
    assert test_hxml =~ "-D exunit"
    assert test_hxml =~ "-D app_name=MyApp"
    refute test_hxml =~ "-D reflaxe_runtime"
  end

  test "directory plan avoids example-only dirs when examples are skipped" do
    directories =
      phoenix_config(basic_modules: true, skip_examples: true)
      |> Mix.Tasks.Haxe.Gen.Project.directories_for_test()

    refute "src_haxe/my_app_hx/utils" in directories
    refute "src_haxe/my_app_hx/live" in directories
  end

  test "directory plan creates example dirs only when their files are generated" do
    directories =
      phoenix_config(basic_modules: true, skip_examples: false)
      |> Mix.Tasks.Haxe.Gen.Project.directories_for_test()

    assert "src_haxe/my_app_hx/utils" in directories
    assert "src_haxe/my_app_hx/live" in directories
  end

  test "phoenix live example template is strict TSX and raw-HEEx free" do
    source =
      phoenix_config(skip_examples: false)
      |> Mix.Tasks.Haxe.Gen.Project.live_example_content_for_test()

    assert source =~ ~S|@:hxx_mode("tsx")|
    assert source =~ "return <div"
    assert source =~ ~S(${assigns.count})
    refute source =~ "<%"
    refute source =~ "hxx("
    refute source =~ "HXX.hxx"
    refute source =~ "@:allow_heex"
  end

  test "test helper patch injects Haxe ExUnit generated test require block" do
    patched = Mix.Tasks.Haxe.Gen.Project.patch_test_helper_content_for_test(@test_helper_minimal)

    assert patched =~ "BEGIN reflaxe_elixir haxe_exunit_require"
    assert patched =~ ~s|Path.wildcard("test/generated/**/*_test.exs")|
    assert patched =~ "Code.require_file(file)"
    assert patched =~ "END reflaxe_elixir haxe_exunit_require"
  end

  test "mix.exs alias patch adds haxe.compile.tests and test alias when missing" do
    patched =
      Mix.Tasks.Haxe.Gen.Project.add_haxe_test_aliases_for_test(@mix_exs_without_test_alias)

    assert patched =~ ~s("haxe.compile.tests": ["cmd haxe build-tests.hxml"])
    assert patched =~ ~s(test: ["haxe.compile.tests", "test"])
  end

  test "mix.exs patch adds the standard aliases configuration when absent" do
    patched =
      Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
        @mix_exs_without_aliases,
        phoenix_config(phoenix: false)
      )

    assert patched =~ "compilers: [:haxe] ++ Mix.compilers()"
    assert patched =~ "haxe: ["
    assert patched =~ "aliases: aliases()"
    assert patched =~ "defp aliases do"
    assert patched =~ ~s("haxe.compile.tests": ["cmd haxe build-tests.hxml"])
    assert patched =~ ~s(test: ["haxe.compile.tests", "test"])
    assert {:ok, _ast} = Code.string_to_quoted(patched)

    assert String.trim_trailing(patched) ==
             patched |> Code.format_string!() |> IO.iodata_to_binary()

    assert patched ==
             Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
               patched,
               phoenix_config(phoenix: false)
             )
  end

  test "mix.exs patch refuses to claim a custom test alias compiles Haxe tests" do
    assert_raise RuntimeError, ~r/cannot safely patch mix\.exs.*No writes occurred/s, fn ->
      Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
        @mix_exs_with_custom_test_alias,
        phoenix_config(phoenix: false)
      )
    end
  end

  test "mix.exs patch distinguishes aliases/0 from an existing aliases/1 function" do
    patched =
      Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
        @mix_exs_with_aliases_arity_one,
        phoenix_config(phoenix: false)
      )

    assert patched =~ "aliases: aliases()"
    assert patched =~ "defp aliases(_opts) do"
    assert patched =~ "defp aliases do"
    assert patched =~ ~s("haxe.compile.tests": ["cmd haxe build-tests.hxml"])
    assert patched =~ ~s(test: ["haxe.compile.tests", "test"])
    assert {:ok, _ast} = Code.string_to_quoted(patched)
    assert [{AliasArityOneProject, _bytecode}] = Code.compile_string(patched)
  after
    :code.purge(AliasArityOneProject)
    :code.delete(AliasArityOneProject)
  end

  test "mix.exs patch ignores commented aliases and rejects a custom test alias" do
    assert_raise RuntimeError,
                 ~r/manual integration with the existing test alias.*No writes/s,
                 fn ->
                   Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
                     @mix_exs_with_commented_haxe_alias,
                     phoenix_config(phoenix: false)
                   )
                 end
  end

  test "mix.exs patch fails closed for an application-owned compiler pipeline" do
    assert_raise RuntimeError,
                 ~r/manual integration with the existing custom compilers: entry.*No writes/s,
                 fn ->
                   Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
                     @mix_exs_with_custom_compilers,
                     phoenix_config(phoenix: false)
                   )
                 end
  end

  test "mix.exs patch fails closed for an application-owned haxe.compile.tests alias" do
    assert_raise RuntimeError,
                 ~r/manual integration with the existing haxe\.compile\.tests alias.*No writes/s,
                 fn ->
                   Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
                     @mix_exs_with_custom_haxe_compile_tests_alias,
                     phoenix_config(phoenix: false)
                   )
                 end
  end

  test "mix.exs patch fails closed for duplicate haxe.compile.tests aliases" do
    assert_raise RuntimeError,
                 ~r/one unambiguous haxe\.compile\.tests alias.*No writes/s,
                 fn ->
                   Mix.Tasks.Haxe.Gen.Project.planned_mix_exs_content_for_test(
                     @mix_exs_with_duplicate_haxe_compile_tests_aliases,
                     phoenix_config(phoenix: false)
                   )
                 end
  end

  test "declining the required mix.exs update cancels preflight" do
    assert_raise RuntimeError, ~r/cancelled.*No writes occurred/s, fn ->
      Mix.Tasks.Haxe.Gen.Project.require_mix_exs_update_consent_for_test(
        "before",
        "after",
        false,
        false
      )
    end

    assert :ok ==
             Mix.Tasks.Haxe.Gen.Project.require_mix_exs_update_consent_for_test(
               "before",
               "after",
               false,
               true
             )

    assert :ok ==
             Mix.Tasks.Haxe.Gen.Project.require_mix_exs_update_consent_for_test(
               "same",
               "same",
               false,
               false
             )
  end

  test "mix.exs publication refuses to overwrite a file changed after preflight" do
    test_dir =
      Path.join(
        System.tmp_dir!(),
        "haxe_gen_project_stale_write_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(test_dir)
    on_exit(fn -> File.rm_rf!(test_dir) end)

    mix_exs_path = Path.join(test_dir, "mix.exs")
    File.write!(mix_exs_path, "consented snapshot")
    plan = %{current: "consented snapshot", updated: "generator update"}

    File.write!(mix_exs_path, "newer application-owned edit")

    assert_raise RuntimeError, ~r/changed after generator preflight and consent/, fn ->
      Mix.Tasks.Haxe.Gen.Project.update_mix_exs_for_test(mix_exs_path, plan)
    end

    assert File.read!(mix_exs_path) == "newer application-owned edit"
  end

  test "mix.exs publication rechecks the preflight snapshot when no update was planned" do
    test_dir =
      Path.join(
        System.tmp_dir!(),
        "haxe_gen_project_stale_noop_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(test_dir)
    on_exit(fn -> File.rm_rf!(test_dir) end)

    mix_exs_path = Path.join(test_dir, "mix.exs")
    File.write!(mix_exs_path, "preflight-complete configuration")

    plan = %{
      current: "preflight-complete configuration",
      updated: "preflight-complete configuration"
    }

    File.write!(mix_exs_path, "newer configuration with different semantics")

    assert_raise RuntimeError, ~r/changed after generator preflight and consent/, fn ->
      Mix.Tasks.Haxe.Gen.Project.update_mix_exs_for_test(mix_exs_path, plan)
    end

    assert File.read!(mix_exs_path) == "newer configuration with different semantics"
  end

  test "LiveReact remains an opt-in Phoenix feature orthogonal to client mode" do
    assert :ok ==
             Mix.Tasks.Haxe.Gen.Project.validate_feature_composition_for_test(%{
               live_react: true,
               phoenix: true,
               skip_npm: false,
               client_mode: :genes
             })

    assert :ok ==
             Mix.Tasks.Haxe.Gen.Project.validate_feature_composition_for_test(%{
               live_react: true,
               phoenix: true,
               skip_npm: false,
               client_mode: :plain_js
             })

    assert_raise RuntimeError, ~r/requires --phoenix/, fn ->
      Mix.Tasks.Haxe.Gen.Project.validate_feature_composition_for_test(%{
        live_react: true,
        phoenix: false,
        skip_npm: false
      })
    end

    assert_raise RuntimeError, ~r/cannot be combined with --skip-npm/, fn ->
      Mix.Tasks.Haxe.Gen.Project.validate_feature_composition_for_test(%{
        live_react: true,
        phoenix: true,
        skip_npm: true
      })
    end
  end

  test "agent bootstrap renders base, Phoenix, and LiveReact profiles from one template" do
    base =
      phoenix_config(phoenix: false)
      |> Mix.Tasks.Haxe.Gen.Project.agent_instructions_content_for_test()

    phoenix =
      phoenix_config(client_mode: :plain_js)
      |> Mix.Tasks.Haxe.Gen.Project.agent_instructions_content_for_test()

    live_react =
      phoenix_config(live_react: true)
      |> Mix.Tasks.Haxe.Gen.Project.agent_instructions_content_for_test()

    assert base =~ "Edit application behavior in `src_haxe/**`"
    assert base =~ "`lib/my_app_hx/**` as generated output"
    refute base =~ "## PhoenixHx"
    refute base =~ "{{"

    assert phoenix =~ "## PhoenixHx"
    assert phoenix =~ ~S(return <section>)
    assert phoenix =~ "The target shape is ordinary HEEx"
    assert phoenix =~ "configured browser client mode is `plain-js`"
    assert phoenix =~ "`plain-js` means Phoenix modules and HEEx may still be Haxe-authored"
    assert phoenix =~ "`genes` means browser bootstrap code and hooks may be authored in Haxe"
    assert phoenix =~ "Interactive development and automated validation"
    assert phoenix =~ "bounded process ownership"
    refute phoenix =~ "## PhoenixHx + LiveReact"
    assert phoenix =~ ~S|Do not introduce `hxx("...")`|

    assert live_react =~ "## PhoenixHx + LiveReact"
    assert live_react =~ "mix haxe.phoenix.live_react --check"
    assert live_react =~ "mix haxe.gen.live_react ComponentName"
    assert live_react =~ "browser events as untrusted input"
    assert live_react =~ "Server-side React rendering is not enabled"
    assert live_react =~ "LiveReact does not itself require Genes"
    assert live_react =~ "inner React component in hand-owned TSX"
    refute live_react =~ "{{"
  end
end
