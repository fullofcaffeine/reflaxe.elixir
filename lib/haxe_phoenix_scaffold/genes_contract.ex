defmodule HaxePhoenixScaffold.GenesContract do
  def build_client_signature() do
    "reflaxe_elixir:build_client_hxml:v2"
  end

  def genes_alias_signature() do
    "reflaxe_elixir:scaffolded_haxe_library:genes:v2"
  end

  def genes_ts_signature() do
    "reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1"
  end

  def genes_ts_hxml() do
    lines([
      "# reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1",
      "# genes-ts — Haxe to classic ESM JavaScript or strict TypeScript/TSX",
      "#",
      "# This file is scaffold-managed by `mix haxe.phoenix.scaffold`. If you customize it, remove",
      "# the signature line above to opt out of future updates.",
      "# Pin provenance: canonical genes-ts v1.37.0 release with Haxe-checked React HXX contracts and soundness fixes.",
      "",
      "# @install: lix --silent download \"gh://github.com/fullofcaffeine/genes-ts#107491cb115ba7abd5628a1f3bcb338aa8cf2685\" into genes-ts/1.37.0/github/107491cb115ba7abd5628a1f3bcb338aa8cf2685",
      "-lib helder.set",
      "${HAXE_LIBCACHE}/genes-ts/1.37.0/github/107491cb115ba7abd5628a1f3bcb338aa8cf2685/extraParams.hxml",
      "-cp ${HAXE_LIBCACHE}/genes-ts/1.37.0/github/107491cb115ba7abd5628a1f3bcb338aa8cf2685/src",
      "-D genes-ts=1.37.0"
    ])
  end

  def genes_alias_hxml() do
    lines([
      "# reflaxe_elixir:scaffolded_haxe_library:genes:v2",
      "# Compatibility alias for projects that still use `-lib genes`.",
      "# Both names resolve the same immutable genes-ts revision.",
      "-lib genes-ts",
      "-D genes=1.37.0"
    ])
  end

  def build_client_hxml() do
    lines([
      "# reflaxe_elixir:build_client_hxml:v2",
      "# Haxe→JavaScript compilation for Phoenix LiveView client-side code",
      "# Generates ES6 modules compatible with esbuild",
      "",
      "# Source directories (client only)",
      "-cp src_haxe/client",
      "-cp src_haxe",
      "# Compile browser source through the pinned genes-ts classic ESM profile.",
      "-lib genes-ts",
      "# Typed Phoenix JS externs (Channels + LiveView)",
      "-lib phoenix_js",
      "",
      "# JavaScript target output",
      "#",
      "# IMPORTANT:",
      "# Haxe deletes the `-js` output file at the start of compilation. Since Phoenix runs esbuild in",
      "# `--watch` mode and `assets/js/app.js` imports `./hx_app.js`, that temporary deletion can race",
      "# esbuild and produce transient \"Could not resolve ./hx_app.js\" errors.",
      "#",
      "# To keep esbuild stable in watch mode, compile into a temporary entry file and then promote",
      "# it into a stable path used by esbuild imports:",
      "# - Haxe writes `assets/js/_hx_app_tmp.js` (and deletes it during rebuilds).",
      "# - A watcher promotes that output into the stable `assets/js/hx_app.js` path atomically.",
      "-js assets/js/_hx_app_tmp.js",
      "-D js-unflatten",
      "--dce=full",
      "",
      "# Haxe 4.3+ optimizations",
      "-D real-position",
      "-D js-source-map",
      "",
      "# Exclude server code from client compilation",
      "--macro exclude('server')",
      "",
      "# Main client entry point",
      "-main client.Boot"
    ])
  end

  def patch_build_client_hxml(content) do
    normalized = normalize(content)

    cond do
      owned_either(
        content,
        "reflaxe_elixir:build_client_hxml:v2",
        "reflaxe_elixir:build_client_hxml:v1",
        "build-client.hxml"
      ) or normalized == normalize(legacy_vendored_build_client_hxml("assets/js/_hx_app_tmp.js")) or
          normalized == normalize(legacy_vendored_build_client_hxml("assets/js/hx_app.js")) ->
        build_client_hxml()

      String.contains?(content, "assets/js/_hx_app_tmp.js") ->
        content

      String.contains?(content, "-js assets/js/hx_app.js") ->
        String.replace(content, "-js assets/js/hx_app.js", "-js assets/js/_hx_app_tmp.js")

      true ->
        content
    end
  end

  def managed_build_client_hxml(content) do
    normalized = normalize(content)

    owned_either(
      content,
      "reflaxe_elixir:build_client_hxml:v2",
      "reflaxe_elixir:build_client_hxml:v1",
      "build-client.hxml"
    ) or normalized == normalize(legacy_vendored_build_client_hxml("assets/js/_hx_app_tmp.js")) or
      normalized == normalize(legacy_vendored_build_client_hxml("assets/js/hx_app.js"))
  end

  def patch_genes_alias_hxml(content) do
    if owned_either(
         content,
         "reflaxe_elixir:scaffolded_haxe_library:genes:v2",
         "reflaxe_elixir:scaffolded_haxe_library:genes:v1",
         "haxe_libraries/genes.hxml"
       ),
       do: genes_alias_hxml(),
       else: content
  end

  def managed_genes_alias_hxml(content) do
    owned_either(
      content,
      "reflaxe_elixir:scaffolded_haxe_library:genes:v2",
      "reflaxe_elixir:scaffolded_haxe_library:genes:v1",
      "haxe_libraries/genes.hxml"
    )
  end

  def patch_genes_ts_hxml(content) do
    if owned_signature(
         content,
         "reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1",
         "haxe_libraries/genes-ts.hxml"
       ),
       do: genes_ts_hxml(),
       else: content
  end

  def managed_genes_ts_hxml(content) do
    owned_signature(
      content,
      "reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1",
      "haxe_libraries/genes-ts.hxml"
    )
  end

  defp owned_signature(content, signature, label) do
    status = HaxeProjectPatch.signature_status(content, signature)

    cond do
      Kernel.===(status, :owned) ->
        true

      Kernel.===(status, :unowned) ->
        false

      true ->
        Kernel.raise(
          "duplicate scaffold ownership signature in " <> label <> ": " <> Kernel.inspect(status)
        )
    end
  end

  defp owned_either(content, current_signature, legacy_signature, label) do
    current_owned = owned_signature(content, current_signature, label)
    legacy_owned = owned_signature(content, legacy_signature, label)
    current_owned or legacy_owned
  end

  defp normalize(content) do
    String.trim(String.replace(content, "\r\n", "\n"))
  end

  defp legacy_vendored_build_client_hxml(output) do
    lines([
      "# Haxe→JavaScript compilation for Phoenix LiveView client-side code",
      "# Generates ES6 modules compatible with esbuild",
      "",
      "# Source directories (client only)",
      "-cp src_haxe/client",
      "-cp src_haxe",
      "# Enable Genes ES6 module generator (uses haxe_libraries/genes.hxml)",
      "-lib genes",
      "# Typed Phoenix JS externs (Channels + LiveView)",
      "-lib phoenix_js",
      "",
      "# NOTE: Our vendored `-lib genes` does not automatically apply genes/extraParams.hxml,",
      "# so we explicitly enable the generator here.",
      "-D js-es=6",
      "--macro genes.Generator.use()",
      "--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')",
      "",
      "# JavaScript target output",
      "#",
      "# IMPORTANT:",
      "# Haxe deletes the `-js` output file at the start of compilation. Since Phoenix runs esbuild in",
      "# `--watch` mode and `assets/js/app.js` imports `./hx_app.js`, that temporary deletion can race",
      "# esbuild and produce transient \"Could not resolve ./hx_app.js\" errors.",
      "#",
      "# To keep esbuild stable in watch mode, compile into a temporary entry file and then promote",
      "# it into a stable path used by esbuild imports:",
      "# - Haxe writes `assets/js/_hx_app_tmp.js` (and deletes it during rebuilds).",
      "# - A watcher promotes that output into the stable `assets/js/hx_app.js` path atomically.",
      "-js #{output}",
      "-D js-unflatten",
      "--dce=full",
      "",
      "# Haxe 4.3+ optimizations",
      "-D real-position",
      "-D js-source-map",
      "",
      "# Exclude server code from client compilation",
      "--macro exclude('server')",
      "",
      "# Main client entry point",
      "-main client.Boot"
    ])
  end

  defp lines(values) do
    "#{Enum.join(values, "\n")}\n"
  end
end
