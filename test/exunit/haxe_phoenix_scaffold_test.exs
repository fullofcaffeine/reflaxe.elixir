defmodule HaxePhoenixScaffoldTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  @minimal_app_js """
  import "phoenix_html"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"

  let Hooks = {};
  let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks})
  liveSocket.connect()
  """

  @phoenix_17ish_app_js """
  import "../css/app.css"
  import "phoenix_html"
  import topbar from "../vendor/topbar"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"

  topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
  window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300))
  window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide())

  const Hooks = {}
  let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks})
  liveSocket.connect()
  """

  @phoenix_18_app_js """
  import "phoenix_html"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"
  import {hooks as colocatedHooks} from "phoenix-colocated/my_app"

  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  const liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks: {...colocatedHooks},
  })

  liveSocket.connect()
  """

  @no_hooks_app_js """
  import "phoenix_html"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"

  let liveSocket = new LiveSocket("/live", Socket, {})
  liveSocket.connect()
  """

  @minimal_dev_exs """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    watchers: [
      esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]}
    ]
  """

  @minimal_mix_exs """
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

    def application do
      [extra_applications: [:logger]]
    end

    defp aliases do
      [
        "assets.setup": ["esbuild.install --if-missing"],
        "assets.build": ["esbuild my_app"],
        "assets.deploy": ["esbuild my_app --minify", "phx.digest"]
      ]
    end
  end
  """

  test "scaffolds build-client + stable hx_app wiring and is idempotent" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)
    assert :ok == HaxePhoenixScaffold.apply!(root)

    build_client = File.read!(Path.join(root, "build-client.hxml"))
    assert build_client =~ "assets/js/_hx_app_tmp.js"

    boot = File.read!(Path.join([root, "src_haxe", "client", "Boot.hx"]))
    assert boot =~ "window.Hooks"

    hx_app = File.read!(Path.join([assets_js, "hx_app.js"]))
    assert hx_app =~ "reflaxe_elixir:hx_app_stub:v1"

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    assert app_js =~ "BEGIN reflaxe_elixir hx_app_import"
    assert app_js =~ ~s(import "./hx_app.js";)
    assert app_js =~ "BEGIN reflaxe_elixir hooks_after_decl"
    assert app_js =~ "Object.assign(Hooks, window.Hooks || {});"
    assert count(app_js, "BEGIN reflaxe_elixir hx_app_import") == 1
    assert count(app_js, "BEGIN reflaxe_elixir hooks_after_decl") == 1

    dev_exs = File.read!(Path.join([config_dir, "dev.exs"]))
    assert dev_exs =~ "BEGIN reflaxe_elixir haxe_client"
    assert dev_exs =~ "haxe_client:"
    assert dev_exs =~ "--promote"
    assert count(dev_exs, "BEGIN reflaxe_elixir haxe_client") == 1

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    assert mix_exs =~ ~s("haxe.compile.client":)
    assert mix_exs =~ "BEGIN reflaxe_elixir haxe_compile_client_alias"
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.build_task"
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.deploy_task"
    assert count(mix_exs, "BEGIN reflaxe_elixir haxe_compile_client_alias") == 1
    assert count(mix_exs, "BEGIN reflaxe_elixir assets.build_task") == 1
    assert count(mix_exs, "BEGIN reflaxe_elixir assets.deploy_task") == 1

    gitignore = File.read!(Path.join(root, ".gitignore"))
    assert gitignore =~ "assets/js/_hx_app_tmp.js"
  end

  test "patches Phoenix 1.7-ish app.js variants without relying on Hooks variable shape" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @phoenix_17ish_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    assert app_js =~ "BEGIN reflaxe_elixir hx_app_import"
    assert app_js =~ "BEGIN reflaxe_elixir hooks_after_decl"
    assert app_js =~ "Object.assign(Hooks, window.Hooks || {});"
  end

  test "patches Phoenix 1.8-ish inline hooks option (no Hooks variable)" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @phoenix_18_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    assert app_js =~ "BEGIN reflaxe_elixir hooks_property"
    assert app_js =~ "hooks: {...colocatedHooks, ...(window.Hooks || {})},"
  end

  test "strict mode fails fast; warn-only mode skips with warning" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @no_hooks_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert_raise RuntimeError,
                 ~r/could not find a `Hooks` declaration or a `hooks:` LiveSocket option/,
                 fn ->
                   HaxePhoenixScaffold.apply!(root, strict: true)
                 end

    stderr =
      capture_io(:stderr, fn ->
        assert :ok == HaxePhoenixScaffold.apply!(root, strict: false)
      end)

    assert stderr =~ "could not find a `Hooks` declaration or a `hooks:` LiveSocket option"
  end

  defp count(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
