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
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [
          check: :boolean,
          remove: :boolean,
          yes: :boolean,
          warn_only: :boolean,
          package_root: :string,
          ssr: :boolean
        ]
      )

    reject_invalid_arguments!(argv, invalid)
    reject_unsupported_options!(opts)

    mode = parse_mode!(opts)
    root = File.cwd!()

    common = [
      package_root: opts[:package_root],
      mix_dependencies: Mix.Project.config()[:deps] || [],
      yes: opts[:yes] || mode == :check,
      warn_only: opts[:warn_only] || false,
      confirm: &Mix.shell().yes?/1,
      report: &Mix.shell().info/1
    ]

    result =
      case mode do
        :apply -> HaxePhoenixLiveReact.apply!(root, common)
        :check -> HaxePhoenixLiveReact.check!(root, common)
        :remove -> HaxePhoenixLiveReact.remove!(root, common)
      end

    report_result(mode, result)
    result
  end

  defp parse_mode!(opts) do
    case {opts[:check] || false, opts[:remove] || false} do
      {true, true} -> raise "--check and --remove are mutually exclusive"
      {true, false} -> :check
      {false, true} -> :remove
      {false, false} -> :apply
    end
  end

  defp reject_invalid_arguments!([], []), do: :ok

  defp reject_invalid_arguments!(argv, invalid) do
    details =
      [
        if(argv != [], do: "unexpected arguments: #{Enum.join(argv, " ")}"),
        if(invalid != [], do: "invalid options: #{inspect(invalid)}")
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("; ")

    raise "invalid haxe.phoenix.live_react invocation (#{details})"
  end

  defp reject_unsupported_options!(opts) do
    if opts[:ssr] do
      raise "--ssr is not supported by the initial PhoenixHx LiveReact integration. No writes occurred. Client-only setup always emits ssr=false."
    end
  end

  defp report_result(_mode, :cancelled) do
    Mix.shell().info("PhoenixHx LiveReact changes cancelled; no writes occurred.")
  end

  defp report_result(:apply, result) do
    Mix.shell().info("PhoenixHx LiveReact integration is current (experimental, client-only).")
    Mix.shell().info("Stock LiveReact identity: #{identity_label(result.dependency)}")
    Mix.shell().info("npm package root: #{result.package_root}")
    Mix.shell().info("Next: npm install#{package_suffix(result.package_root)}")
    Mix.shell().info("Then verify: mix haxe.phoenix.live_react --check")
  end

  defp report_result(:check, result) do
    Mix.shell().info("PhoenixHx LiveReact check passed; no writes occurred.")
    Mix.shell().info("Stock LiveReact identity: #{identity_label(result.dependency)}")
  end

  defp report_result(:remove, result) do
    Mix.shell().info("Removed all currently owned PhoenixHx LiveReact state.")

    if result.retained_package_keys != [] do
      Mix.shell().info(
        "Retained package keys used by hand-owned browser source: #{Enum.join(result.retained_package_keys, ", ")}"
      )
    end

    if result.retained_live_react_dependency do
      Mix.shell().info(
        "Retained the stock :live_react Mix dependency and lock entry because hand-owned browser source still imports live_react."
      )
    end

    Mix.shell().info(
      "Run npm install#{package_suffix(result.package_root)} to converge the npm lockfile."
    )
  end

  defp identity_label(%{"sourceKind" => "git"} = identity),
    do: "#{identity["repository"]}@#{identity["resolvedRevision"]}"

  defp identity_label(%{"sourceKind" => "hex"} = identity),
    do: "hex:#{identity["package"]}@#{identity["resolvedVersion"]}"

  defp identity_label(%{"sourceKind" => "path"} = identity),
    do: "path:#{identity["path"]}@#{identity["packageVersion"]}"

  defp package_suffix("."), do: ""
  defp package_suffix(path), do: " --prefix #{path}"
end
