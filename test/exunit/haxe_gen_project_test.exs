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

  test "build.hxml enables strict TSX mode for phoenix scaffolds" do
    config = %{
      haxe_namespace: "my_app_hx",
      elixir_namespace: "MyApp",
      haxe_dir: "src_haxe",
      output_dir: "lib/my_app_hx",
      basic_modules: false,
      phoenix: true,
      skip_examples: true
    }

    hxml = Mix.Tasks.Haxe.Gen.Project.build_hxml_content_for_test(config)

    assert hxml =~ "-D hxx_string_to_sigil"
    assert hxml =~ "-D hxx_mode=tsx"
  end

  test "build.hxml does not inject TSX flag for non-phoenix scaffolds" do
    config = %{
      haxe_namespace: "my_app_hx",
      elixir_namespace: "MyApp",
      haxe_dir: "src_haxe",
      output_dir: "lib/my_app_hx",
      basic_modules: false,
      phoenix: false,
      skip_examples: true
    }

    hxml = Mix.Tasks.Haxe.Gen.Project.build_hxml_content_for_test(config)

    refute hxml =~ "-D hxx_string_to_sigil"
    refute hxml =~ "-D hxx_mode=tsx"
  end

  test "build-tests.hxml includes ExUnit and generated test output wiring" do
    config = %{
      haxe_namespace: "my_app_hx",
      elixir_namespace: "MyApp",
      haxe_dir: "src_haxe",
      output_dir: "lib/my_app_hx",
      basic_modules: false,
      phoenix: true,
      skip_examples: true
    }

    test_hxml = Mix.Tasks.Haxe.Gen.Project.build_tests_hxml_content_for_test(config)

    assert test_hxml =~ "-cp src_haxe"
    assert test_hxml =~ "-cp test_haxe"
    assert test_hxml =~ "-D elixir_output=test/generated"
    assert test_hxml =~ "-D elixir_output_exs"
    assert test_hxml =~ "-D exunit"
    assert test_hxml =~ "-D app_name=MyApp"
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
end
