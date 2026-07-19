defmodule Mix.Tasks.Haxe.Phoenix.LiveReact do
  @moduledoc """
  Installs, verifies, or removes the opt-in stock LiveReact/Vite integration.

  PhoenixHx owns project wiring and generated ownership metadata. Stock
  `live_react` remains the server/browser runtime.

      mix haxe.phoenix.live_react
      mix haxe.phoenix.live_react --check
      mix haxe.phoenix.live_react --remove

  ## Options

    * `--check` - compare the complete desired integration without writing or fetching
    * `--remove` - remove only signature/marker/key-owned integration state
    * `--yes` - do not prompt before apply or remove
    * `--warn-only` - retain advisory warnings; never bypass ownership or identity failures
    * `--package-root PATH` - select the tested `.` or `assets` npm package root

  The initial integration is client-only. SSR, slots, uploads, streams, and
  request-selected component modules are intentionally unsupported.
  """

  use Mix.Task

  @shortdoc "Sets up/checks/removes stock LiveReact + Vite"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    parsed = OptionParser.parse(args, parser_options())
    options = elem(parsed, 0)
    argv = elem(parsed, 1)
    invalid = elem(parsed, 2)
    reject_invalid_arguments(argv, invalid)
    reject_unsupported_options(options)
    mode = parse_mode(options)
    root = File.cwd!()
    project_config = Mix.Project.config()
    app_name = Keyword.get(project_config, :app, nil)
    mix_dependencies = Keyword.get(project_config, :deps, [])
    package_root = Keyword.get(options, :package_root, nil)
    confirmed = Keyword.get(options, :yes, false) or mode == :check
    warn_only = Keyword.get(options, :warn_only, false)
    confirm = fn message -> Mix.shell().yes?(message) end
    report = fn message -> Mix.shell().info(message) end

    common = [
      {:app_name,
       if Kernel.is_nil(app_name) do
         nil
       else
         Kernel.to_string(app_name)
       end},
      {:package_root, package_root},
      {:mix_dependencies, mix_dependencies},
      {:yes, confirmed},
      {:warn_only, warn_only},
      {:confirm, confirm},
      {:report, report}
    ]

    result =
      cond do
        mode == :apply -> HaxePhoenixLiveReact.apply!(root, common)
        mode == :check -> HaxePhoenixLiveReact.check!(root, common)
        true -> HaxePhoenixLiveReact.remove!(root, common)
      end

    report_result(mode, result)
    result
  end

  defp parser_options() do
    switches = [
      {:check, :boolean},
      {:remove, :boolean},
      {:yes, :boolean},
      {:warn_only, :boolean},
      {:package_root, :string},
      {:ssr, :boolean}
    ]

    [{:strict, switches}]
  end

  defp parse_mode(options) do
    check = Keyword.get(options, :check, false)
    remove = Keyword.get(options, :remove, false)

    if check and remove do
      Kernel.raise("--check and --remove are mutually exclusive")
    else
      if check do
        :check
      else
        if remove, do: :remove, else: :apply
      end
    end
  end

  defp reject_invalid_arguments(argv, invalid) do
    if length(argv) == 0 and length(invalid) == 0 do
      nil
    else
      details =
        if length(argv) == 0 do
          ""
        else
          "unexpected arguments: #{Enum.join(argv, " ")}"
        end

      details =
        if length(invalid) != 0 do
          details =
            if details != "" do
              "#{details}; "
            else
              details
            end

          "#{details}invalid options: #{Kernel.inspect(invalid)}"
        else
          details
        end

      Kernel.raise("invalid haxe.phoenix.live_react invocation (#{details})")
    end
  end

  defp reject_unsupported_options(options) do
    if Keyword.get(options, :ssr, false) do
      Kernel.raise(
        "--ssr is not supported by the initial PhoenixHx LiveReact integration. No writes occurred. Client-only setup always emits ssr=false."
      )
    end
  end

  defp report_result(mode, result) do
    if result == :cancelled do
      Mix.shell().info("PhoenixHx LiveReact changes cancelled; no writes occurred.")
    else
      report_completed_result(mode, result)
    end
  end

  defp report_completed_result(mode, result) do
    cond do
      mode == :apply ->
        package_root = top_level_string(result, :package_root)

        Mix.shell().info(
          "PhoenixHx LiveReact integration is current (experimental, client-only)."
        )

        Mix.shell().info(
          "Stock LiveReact identity: " <> identity_label(top_level_value(result, :dependency))
        )

        Mix.shell().info("npm package root: " <> package_root)
        Mix.shell().info("Next: npm install" <> package_suffix(package_root))
        Mix.shell().info("Then verify: mix haxe.phoenix.live_react --check")

      mode == :check ->
        Mix.shell().info("PhoenixHx LiveReact check passed; no writes occurred.")

        Mix.shell().info(
          "Stock LiveReact identity: " <> identity_label(top_level_value(result, :dependency))
        )

      true ->
        Mix.shell().info("Removed all currently owned PhoenixHx LiveReact state.")
        retained_keys = Enum.to_list(top_level_value(result, :retained_package_keys))

        if length(retained_keys) != 0 do
          Mix.shell().info(
            "Retained package keys used by hand-owned browser source: " <>
              Enum.join(retained_keys, ", ")
          )
        end

        if top_level_value(result, :retained_live_react_dependency) == true do
          Mix.shell().info(
            "Retained the stock :live_react Mix dependency and lock entry because hand-owned browser source still imports live_react."
          )
        end

        Mix.shell().info(
          "Run npm install" <>
            package_suffix(top_level_string(result, :package_root)) <>
            " to converge the npm lockfile."
        )
    end
  end

  defp identity_label(identity) do
    source_kind = string_key_string(identity, "sourceKind")

    if source_kind == "git" do
      "#{string_key_string(identity, "repository")}@#{string_key_string(identity, "resolvedRevision")}"
    else
      if source_kind == "hex" do
        "hex:#{string_key_string(identity, "package")}@#{string_key_string(identity, "resolvedVersion")}"
      else
        if source_kind == "path" do
          "path:#{string_key_string(identity, "path")}@#{string_key_string(identity, "packageVersion")}"
        else
          Kernel.raise(
            "unsupported LiveReact dependency identity returned by HaxePhoenixLiveReact"
          )
        end
      end
    end
  end

  defp top_level_string(result, key) do
    Kernel.to_string(top_level_value(result, key))
  end

  defp top_level_value(result, key) do
    Map.get(result, key)
  end

  defp string_key_string(result, key) do
    Kernel.to_string(Map.get(result, key))
  end

  defp package_suffix(path) do
    if path == "." do
      ""
    else
      " --prefix #{path}"
    end
  end
end
