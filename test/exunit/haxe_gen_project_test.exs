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

  @test_helper_minimal """
  ExUnit.start()
  """

  defp phoenix_config(overrides \\ []) do
    Map.merge(
      %{
        haxe_namespace: "my_app_hx",
        elixir_namespace: "MyApp",
        module_name: "MyApp",
        haxe_dir: "src_haxe",
        output_dir: "lib/my_app_hx",
        basic_modules: false,
        phoenix: true,
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
    assert patched =~ ~s("test": ["haxe.compile.tests", "test"])
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
end
