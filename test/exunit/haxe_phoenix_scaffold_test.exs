# LEGACY TEST MIGRATION BOUNDARY: this scaffold suite predates the repository's
# Haxe-first ExUnit rule. haxe.elixir.codex-6nb owns its Haxe migration; until
# then, pin assertions delegate to the Haxe-generated GenesContract rather than
# duplicating dependency policy in handwritten Elixir.
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

  @phoenix_17_default_no_hooks_app_js """
  import "../css/app.css"
  import "phoenix_html"
  import topbar from "../vendor/topbar"
  import {Socket} from "phoenix"
  import {LiveSocket} from "phoenix_live_view"

  topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
  window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300))
  window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide())

  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  let liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    longPollFallbackMs: 2500
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

  @minimal_root_layout_no_boilerplate """
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    </head>
    <body>
      <%= @inner_content %>
    </body>
  </html>
  """

  @dev_exs_no_watchers """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000]
  """

  @minimal_dev_exs """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    watchers: [
      esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]}
    ]
  """

  @dev_exs_watchers_no_space """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    watchers:[
      esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]}
    ]
  """

  @dev_exs_watchers_tailwind """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    watchers: [
      esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
      tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
    ]
  """

  @dev_exs_with_unmanaged_haxe_client """
  import Config

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    watchers: [
      haxe_client: [
        "mix",
        "haxe.watch",
        "--hxml",
        "build-client.hxml",
        "--dirs",
        "src_haxe"
      ]
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

  @mix_exs_with_unmanaged_haxe_compile_client """
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
        "haxe.compile.client": ["haxe.watch --once --hxml build-client.hxml"],
        "assets.build": ["esbuild my_app"],
        "assets.deploy": ["esbuild my_app --minify", "phx.digest"]
      ]
    end
  end
  """

  @mix_exs_def_aliases """
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

    def aliases do
      [
        "assets.setup": ["esbuild.install --if-missing"],
        "assets.build": ["esbuild my_app"],
        "assets.deploy": ["esbuild my_app --minify", "phx.digest"]
      ]
    end
  end
  """

  @mix_exs_assets_spacing """
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
        "assets.setup" : ["esbuild.install --if-missing"],
        "assets.build" : ["esbuild my_app"],
        "assets.deploy" : ["esbuild my_app --minify", "phx.digest"]
      ]
    end
  end
  """

  @mix_exs_tailwind_assets """
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
        "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
        "assets.build": ["tailwind my_app", "esbuild my_app"],
        "assets.deploy": ["tailwind my_app --minify", "esbuild my_app --minify", "phx.digest"]
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
    first_tree = file_tree(root)
    assert :ok == HaxePhoenixScaffold.apply!(root)
    assert file_tree(root) == first_tree

    genes_hxml = File.read!(Path.join([root, "haxe_libraries", "genes.hxml"]))
    assert genes_hxml =~ "reflaxe_elixir:scaffolded_haxe_library:genes:v2"
    assert genes_hxml =~ "-lib genes-ts"
    refute genes_hxml =~ "vendor/genes"

    genes_ts_hxml = File.read!(Path.join([root, "haxe_libraries", "genes-ts.hxml"]))
    assert genes_ts_hxml == HaxePhoenixScaffold.GenesContract.genes_ts_hxml()
    assert genes_ts_hxml =~ "reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1"
    assert genes_ts_hxml =~ "-lib helder.set"
    refute genes_ts_hxml =~ "temporary admission pin"
    assert genes_ts_hxml =~ "/extraParams.hxml"

    phoenix_js_hxml = File.read!(Path.join([root, "haxe_libraries", "phoenix_js.hxml"]))
    assert phoenix_js_hxml =~ "reflaxe_elixir:scaffolded_haxe_library:phoenix_js:v1"
    assert phoenix_js_hxml =~ "-cp ${SCOPE_DIR}/deps/reflaxe_elixir/vendor/phoenix_js/src"
    assert phoenix_js_hxml =~ "-cp ${SCOPE_DIR}/deps/reflaxe_elixir/vendor/phoenix_shared/src"

    helder_set_hxml = File.read!(Path.join([root, "haxe_libraries", "helder.set.hxml"]))
    assert helder_set_hxml =~ "reflaxe_elixir:scaffolded_haxe_library:helder.set:v1"
    assert helder_set_hxml =~ "${HAXE_LIBCACHE}/helder.set/0.3.1/haxelib/src"

    build_client = File.read!(Path.join(root, "build-client.hxml"))
    assert build_client =~ "reflaxe_elixir:build_client_hxml:v2"
    assert build_client =~ "-lib genes-ts"
    assert build_client =~ "assets/js/_hx_app_tmp.js"
    refute build_client =~ "genes.Generator.use()"

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
    assert gitignore =~ "assets/js/hx_app.js"
  end

  test "adds root layout baseline boilerplate when template exists" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_root_layout_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])
    root_layout_dir = Path.join([root, "lib", "my_app_web", "components", "layouts"])
    root_layout_path = Path.join(root_layout_dir, "root.html.heex")

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)
    File.mkdir_p!(root_layout_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")
    File.write!(root_layout_path, @minimal_root_layout_no_boilerplate)

    assert :ok == HaxePhoenixScaffold.apply!(root)
    assert :ok == HaxePhoenixScaffold.apply!(root)

    root_layout = File.read!(root_layout_path)
    assert root_layout =~ "<!DOCTYPE html>"
    assert root_layout =~ ~s(name="csrf-token")
    assert root_layout =~ "phx-track-static"
    assert root_layout =~ ~s(src={~p"/assets/app.js"})
    assert count(root_layout, "<!DOCTYPE html>") == 1
    assert count(root_layout, "csrf-token") == 1
    assert count(root_layout, "phx-track-static") == 1
  end

  test "does not clobber custom haxe_libraries stubs without signature" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_custom_libs_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)
    File.mkdir_p!(Path.join(root, "haxe_libraries"))

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    custom_genes = "# custom genes.hxml\n-cp vendor/genes/src\n"
    File.write!(Path.join([root, "haxe_libraries", "genes.hxml"]), custom_genes)

    assert :ok == HaxePhoenixScaffold.apply!(root)
    assert File.read!(Path.join([root, "haxe_libraries", "genes.hxml"])) == custom_genes
    assert File.exists?(Path.join([root, "haxe_libraries", "genes-ts.hxml"]))
  end

  test "migrates the scaffold-owned vendored Genes descriptor to the exact genes-ts release" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_legacy_genes_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])
    haxe_libraries = Path.join(root, "haxe_libraries")

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)
    File.mkdir_p!(haxe_libraries)
    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    File.write!(
      Path.join(haxe_libraries, "genes.hxml"),
      "# reflaxe_elixir:scaffolded_haxe_library:genes:v1\n-cp ${SCOPE_DIR}/deps/reflaxe_elixir/vendor/genes/src\n"
    )

    assert :ok == HaxePhoenixScaffold.apply!(root)

    alias_hxml = File.read!(Path.join(haxe_libraries, "genes.hxml"))
    assert alias_hxml =~ "reflaxe_elixir:scaffolded_haxe_library:genes:v2"
    assert alias_hxml =~ "-lib genes-ts"
    refute alias_hxml =~ "vendor/genes"

    canonical_hxml = File.read!(Path.join(haxe_libraries, "genes-ts.hxml"))
    assert canonical_hxml == HaxePhoenixScaffold.GenesContract.genes_ts_hxml()
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

  test "patches Phoenix 1.7 default app.js (no Hooks var, no hooks property)" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @phoenix_17_default_no_hooks_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    assert app_js =~ "BEGIN reflaxe_elixir hx_app_import"
    assert app_js =~ "BEGIN reflaxe_elixir hooks_property"
    assert app_js =~ "hooks: window.Hooks || {},"
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

  test "patches inline empty LiveSocket options object by inserting hooks property" do
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

    assert :ok == HaxePhoenixScaffold.apply!(root)

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    assert app_js =~ "BEGIN reflaxe_elixir hooks_property"
    assert app_js =~ "hooks: window.Hooks || {},"
  end

  test "patches dev.exs + mix.exs when formatted differently" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_fmt_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @phoenix_17ish_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @dev_exs_watchers_no_space)
    File.write!(Path.join(root, "mix.exs"), @mix_exs_def_aliases)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    dev_exs = File.read!(Path.join(config_dir, "dev.exs"))
    assert dev_exs =~ "BEGIN reflaxe_elixir haxe_client"

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    assert mix_exs =~ "BEGIN reflaxe_elixir haxe_compile_client_alias"
  end

  test "patches mix.exs assets aliases when spacing varies" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_mix_spacing_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @mix_exs_assets_spacing)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.build_task"
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.deploy_task"
  end

  test "patches dev.exs with multiple watchers (tailwind + esbuild)" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_multi_watchers_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @phoenix_17ish_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @dev_exs_watchers_tailwind)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    dev_exs = File.read!(Path.join(config_dir, "dev.exs"))
    assert dev_exs =~ "BEGIN reflaxe_elixir haxe_client"
    assert count(dev_exs, "BEGIN reflaxe_elixir haxe_client") == 1
  end

  test "patches mix.exs assets aliases when tailwind is present" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_mix_tailwind_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @mix_exs_tailwind_assets)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root)

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.build_task"
    assert mix_exs =~ "BEGIN reflaxe_elixir assets.deploy_task"
  end

  test "does not clobber a user-custom hx_app.js" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_custom_hx_app_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    custom = "// user custom hx_app\nexport const hello = 1;\n"
    File.write!(Path.join(assets_js, "hx_app.js"), custom)

    assert :ok == HaxePhoenixScaffold.apply!(root)
    assert File.read!(Path.join(assets_js, "hx_app.js")) == custom
  end

  test "migrates build-client.hxml -js target from stable path to temp path" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_build_client_migrate_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    File.write!(
      Path.join(root, "build-client.hxml"),
      "-lib reflaxe.elixir\n-cp src_haxe\n-js assets/js/hx_app.js\n--main client.Boot\n"
    )

    assert :ok == HaxePhoenixScaffold.apply!(root)

    build_client = File.read!(Path.join(root, "build-client.hxml"))
    assert build_client =~ "-js assets/js/_hx_app_tmp.js"
    refute build_client =~ "-js assets/js/hx_app.js\n"
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
    File.write!(Path.join(config_dir, "dev.exs"), @dev_exs_no_watchers)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert_raise RuntimeError,
                 ~r/could not find a `watchers:` list/,
                 fn ->
                   HaxePhoenixScaffold.apply!(root, strict: true)
                 end

    stderr =
      capture_io(:stderr, fn ->
        assert :ok == HaxePhoenixScaffold.apply!(root, strict: false)
      end)

    assert stderr =~ "could not find a `watchers:` list"
  end

  test "a late validation error leaves the entire scaffold tree untouched" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_preflight_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])
    root_layout_dir = Path.join([root, "lib", "my_app_web", "components", "layouts"])
    root_layout_path = Path.join(root_layout_dir, "root.html.heex")

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)
    File.mkdir_p!(root_layout_dir)
    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @dev_exs_no_watchers)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")
    File.write!(root_layout_path, @minimal_root_layout_no_boilerplate)

    before = file_tree(root)

    assert_raise RuntimeError, ~r/could not find a `watchers:` list/, fn ->
      HaxePhoenixScaffold.apply!(root, strict: true)
    end

    assert file_tree(root) == before
    refute File.exists?(Path.join(root, ".reflaxe-elixir-project-patch"))
  end

  test "malformed ownership markers remain fatal in warn-only mode without mutations" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_bad_marker_#{System.unique_integer([:positive])}"
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

    app_js_path = Path.join(assets_js, "app.js")

    File.write!(
      app_js_path,
      String.replace(
        File.read!(app_js_path),
        "// BEGIN reflaxe_elixir hx_app_import",
        "// BEGIN reflaxe_elixir hx_app_import\n// BEGIN reflaxe_elixir hx_app_import",
        global: false
      )
    )

    before = file_tree(root)

    assert_raise RuntimeError, ~r/malformed or overlapping reflaxe_elixir marker blocks/, fn ->
      HaxePhoenixScaffold.apply!(root, strict: false)
    end

    assert file_tree(root) == before
    refute File.exists?(Path.join(root, ".reflaxe-elixir-project-patch"))
  end

  test "strict mode fails fast on unmanaged haxe_client watcher; warn-only warns and skips" do
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
    File.write!(Path.join(config_dir, "dev.exs"), @dev_exs_with_unmanaged_haxe_client)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert_raise RuntimeError,
                 ~r/found an existing haxe_client watcher entry, but it is not marker-managed/,
                 fn ->
                   HaxePhoenixScaffold.apply!(root, strict: true)
                 end

    stderr =
      capture_io(:stderr, fn ->
        assert :ok == HaxePhoenixScaffold.apply!(root, strict: false)
      end)

    assert stderr =~ "found an existing haxe_client watcher entry"
  end

  test "strict mode fails fast on unmanaged haxe.compile.client alias; warn-only warns and skips" do
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
    File.write!(Path.join(root, "mix.exs"), @mix_exs_with_unmanaged_haxe_compile_client)
    File.write!(Path.join(root, ".gitignore"), "")

    assert_raise RuntimeError,
                 ~r/found an existing \"haxe\.compile\.client\" alias, but it is not marker-managed/,
                 fn ->
                   HaxePhoenixScaffold.apply!(root, strict: true)
                 end

    stderr =
      capture_io(:stderr, fn ->
        assert :ok == HaxePhoenixScaffold.apply!(root, strict: false)
      end)

    assert stderr =~ "found an existing \"haxe.compile.client\" alias"
  end

  test "plain-js mode removes scaffold-managed genes wiring" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_plain_js_remove_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    assert :ok == HaxePhoenixScaffold.apply!(root, client_mode: :genes)
    assert File.exists?(Path.join(root, "build-client.hxml"))
    assert File.exists?(Path.join([root, "src_haxe", "client", "Boot.hx"]))
    assert File.exists?(Path.join([assets_js, "hx_app.js"]))

    assert :ok == HaxePhoenixScaffold.apply!(root, client_mode: :plain_js, yes: true)

    refute File.exists?(Path.join(root, "build-client.hxml"))
    refute File.exists?(Path.join([root, "src_haxe", "client", "Boot.hx"]))
    refute File.exists?(Path.join([assets_js, "hx_app.js"]))
    refute File.exists?(Path.join([root, "haxe_libraries", "genes.hxml"]))
    refute File.exists?(Path.join([root, "haxe_libraries", "genes-ts.hxml"]))
    refute File.exists?(Path.join([root, "haxe_libraries", "phoenix_js.hxml"]))
    refute File.exists?(Path.join([root, "haxe_libraries", "helder.set.hxml"]))

    app_js = File.read!(Path.join([assets_js, "app.js"]))
    refute app_js =~ "BEGIN reflaxe_elixir"
    refute app_js =~ ~s(import "./hx_app.js";)

    dev_exs = File.read!(Path.join([config_dir, "dev.exs"]))
    refute dev_exs =~ "BEGIN reflaxe_elixir haxe_client"
    refute dev_exs =~ "haxe_client:"

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    refute mix_exs =~ "BEGIN reflaxe_elixir haxe_compile_client_alias"
    refute mix_exs =~ "BEGIN reflaxe_elixir assets.build_task"
    refute mix_exs =~ "BEGIN reflaxe_elixir assets.deploy_task"
    refute mix_exs =~ ~s("haxe.compile.client")

    gitignore = File.read!(Path.join(root, ".gitignore"))
    refute gitignore =~ "assets/js/_hx_app_tmp.js"
    refute gitignore =~ "assets/js/hx_app.js"

    plain_js_tree = file_tree(root)
    assert :ok == HaxePhoenixScaffold.apply!(root, client_mode: :plain_js, yes: true)
    assert file_tree(root) == plain_js_tree
  end

  test "plain-js mode keeps custom client files and warns" do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_scaffold_plain_js_keep_custom_#{System.unique_integer([:positive])}"
      )

    assets_js = Path.join([root, "assets", "js"])
    config_dir = Path.join([root, "config"])

    File.mkdir_p!(assets_js)
    File.mkdir_p!(config_dir)
    File.mkdir_p!(Path.join([root, "src_haxe", "client"]))
    File.mkdir_p!(Path.join(root, "haxe_libraries"))

    File.write!(Path.join(assets_js, "app.js"), @minimal_app_js)
    File.write!(Path.join(config_dir, "dev.exs"), @minimal_dev_exs)
    File.write!(Path.join(root, "mix.exs"), @minimal_mix_exs)
    File.write!(Path.join(root, ".gitignore"), "")

    File.write!(
      Path.join(root, "build-client.hxml"),
      "-cp src_haxe\n-js assets/js/custom.js\n-main client.Boot\n"
    )

    File.write!(
      Path.join([root, "src_haxe", "client", "Boot.hx"]),
      "package client;\nclass Boot { public static function main() {} }\n"
    )

    File.write!(Path.join([assets_js, "hx_app.js"]), "// custom client bundle stub\n")
    File.write!(Path.join([root, "haxe_libraries", "genes.hxml"]), "-cp vendor/genes/src\n")

    stderr =
      capture_io(:stderr, fn ->
        assert :ok == HaxePhoenixScaffold.apply!(root, client_mode: :plain_js, yes: true)
      end)

    assert stderr =~ "plain-js mode kept custom files"
    assert File.exists?(Path.join(root, "build-client.hxml"))
    assert File.exists?(Path.join([root, "src_haxe", "client", "Boot.hx"]))
    assert File.exists?(Path.join([assets_js, "hx_app.js"]))
    assert File.exists?(Path.join([root, "haxe_libraries", "genes.hxml"]))
  end

  defp count(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp file_tree(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Map.new(fn path -> {Path.relative_to(path, root), File.read!(path)} end)
  end
end
