defmodule Mix.Tasks.Haxe.Gen.ProjectTest do
  use ExUnit.Case, async: true

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
end
