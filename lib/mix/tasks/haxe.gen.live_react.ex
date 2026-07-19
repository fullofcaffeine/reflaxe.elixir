defmodule Mix.Tasks.Haxe.Gen.LiveReact do
  @moduledoc """
  Registers a closed React island and optionally scaffolds hand-owned source.

      mix haxe.gen.live_react PreferenceStudio
      mix haxe.gen.live_react PreferenceStudio --existing
      mix haxe.gen.live_react PreferenceStudio --remove
      mix haxe.gen.live_react PreferenceStudio --package-root assets

  The default creates one strict Haxe wrapper, one trusted TSX boundary, and
  one inner TSX component. Those files become application-owned immediately;
  reruns and removal never rewrite or delete them.
  """

  use Mix.Task

  @shortdoc "Registers a typed stock LiveReact island"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    parsed = OptionParser.parse(args, parser_options())
    options = elem(parsed, 0)
    argv = elem(parsed, 1)
    invalid = elem(parsed, 2)

    if length(invalid) != 0 do
      Kernel.raise("invalid haxe.gen.live_react options: #{Kernel.inspect(invalid)}")
    end

    if length(argv) != 1 do
      Kernel.raise(
        "expected one static PascalCase component name. Usage: mix haxe.gen.live_react PreferenceStudio [--existing|--remove]"
      )
    end

    remove = Keyword.get(options, :remove, false)
    use_existing = Keyword.get(options, :existing, false)
    module_path = Keyword.get(options, :module, nil)
    export_name = Keyword.get(options, :export, nil)
    package_root = Keyword.get(options, :package_root, nil)

    if remove and
         (use_existing or not Kernel.is_nil(module_path) or not Kernel.is_nil(export_name)) do
      Kernel.raise(
        "--remove cannot be combined with --existing, --module, or --export. No writes occurred."
      )
    end

    if not remove and not use_existing and
         (not Kernel.is_nil(module_path) or not Kernel.is_nil(export_name)) do
      Kernel.raise(
        "--module and --export adopt hand-owned source and therefore require --existing. No writes occurred."
      )
    end

    project_config = Mix.Project.config()
    app_name = Kernel.to_string(Keyword.get(project_config, :app, nil))
    confirmed = Keyword.get(options, :yes, false)
    confirm = fn message -> Mix.shell().yes?(message) end
    report = fn message -> Mix.shell().info(message) end

    common = [
      {:app_name, app_name},
      {:module_path, module_path},
      {:export_name, export_name},
      {:package_root, package_root},
      {:existing, use_existing},
      {:yes, confirmed},
      {:confirm, confirm},
      {:report, report}
    ]

    result =
      if remove do
        HaxePhoenixLiveReact.remove_component!(File.cwd!(), Enum.at(argv, 0), common)
      else
        HaxePhoenixLiveReact.add_component!(File.cwd!(), Enum.at(argv, 0), common)
      end

    report_result(result)
    result
  end

  defp parser_options() do
    switches = [
      {:remove, :boolean},
      {:existing, :boolean},
      {:module, :string},
      {:export, :string},
      {:package_root, :string},
      {:yes, :boolean}
    ]

    [{:strict, switches}]
  end

  defp report_result(result) do
    if result == :cancelled do
      Mix.shell().info("LiveReact component changes cancelled; no writes occurred.")
      nil
    else
      mode = Map.get(result, :mode)
      name = Kernel.to_string(Map.get(result, :name))
      created = Map.get(result, :created_files)
      retained = Map.get(result, :retained_files)

      cond do
        mode == :add_component ->
          Mix.shell().info(
            "LiveReact component " <> name <> " is registered in the static registry."
          )

          if length(created) != 0 do
            Mix.shell().info(
              "Created hand-owned starter source:\n" <>
                Enum.map_join(created, "\n", fn path -> "  * " <> path end)
            )
          else
            Mix.shell().info(
              "No starter source was changed; existing application source remains hand-owned."
            )
          end

          Mix.shell().info(
            "Next: review the closed Haxe assigns and trusted TypeScript boundary, add a Live Event Protocol adapter for client pushes, then compile Haxe and run the Vite type/build checks."
          )

        mode == :remove_component ->
          Mix.shell().info("Removed " <> name <> " from the static LiveReact registry.")

          if length(retained) != 0 do
            Mix.shell().info(
              "Retained hand-owned source:\n" <>
                Enum.map_join(retained, "\n", fn path -> "  * " <> path end)
            )
          end

        true ->
          nil
      end
    end
  end
end
