package phoenix_scaffold_tooling;

import elixir.Enum;
import elixir.ElixirString;
import elixir.Kernel;
import elixir.types.Atom;
import elixir.types.Term;

@:native("HaxeProjectPatch")
private extern class ProjectPatchApi {
	@:native("signature_status")
	static function signatureStatus(content:String, signature:String):Term;
}

/**
 * Owns the immutable genes-ts dependency and Phoenix client HXML contract.
 *
 * Why: dependency identity and generated project content are deterministic
 * repository policy, so they belong in Haxe-authored dogfood rather than the
 * legacy handwritten scaffold orchestrator.
 *
 * What: both the canonical `genes-ts` library file and legacy `genes` alias
 * resolve one exact fetchable upstream revision. New browser builds select the classic
 * ESM profile explicitly through `-lib genes-ts`; the same compiler can emit
 * strict TypeScript/TSX when a separate build adds `-D genes.ts`.
 *
 * How: this module is compiled ahead of time to reviewable Elixir. The Mix
 * scaffold calls these pure functions and publishes their returned text through
 * the existing ownership-safe project-patch transaction.
 */
@:keep
@:native("HaxePhoenixScaffold.GenesContract")
class GenesContract {
	public static inline final VERSION = "1.36.3";
	public static inline final COMMIT = "51dc422c2ec930604dfd928d2a112ead354362e3";
	public static inline final PIN_NOTE = "temporary admission pin from codex/output-blank-line-whitespace; replace with the canonical merge or release commit";
	public static inline final BUILD_CLIENT_SIGNATURE = "reflaxe_elixir:build_client_hxml:v2";
	public static inline final LEGACY_BUILD_CLIENT_SIGNATURE = "reflaxe_elixir:build_client_hxml:v1";
	public static inline final GENES_ALIAS_SIGNATURE = "reflaxe_elixir:scaffolded_haxe_library:genes:v2";
	public static inline final LEGACY_GENES_ALIAS_SIGNATURE = "reflaxe_elixir:scaffolded_haxe_library:genes:v1";
	public static inline final GENES_TS_SIGNATURE = "reflaxe_elixir:scaffolded_haxe_library:genes-ts:v1";

	static inline final OWNED:Atom = "owned";
	static inline final UNOWNED:Atom = "unowned";

	/** Expose the current build-file signature to the legacy host orchestrator. */
	public static function buildClientSignature():String {
		return BUILD_CLIENT_SIGNATURE;
	}

	/** Expose the compatibility-alias signature to ownership-safe removal. */
	public static function genesAliasSignature():String {
		return GENES_ALIAS_SIGNATURE;
	}

	/** Expose the canonical dependency signature to ownership-safe removal. */
	public static function genesTsSignature():String {
		return GENES_TS_SIGNATURE;
	}

	/** Render the canonical immutable Lix descriptor consumed by clean builds. */
	public static function genesTsHxml():String {
		return lines(["# " + GENES_TS_SIGNATURE,
			"# genes-ts — Haxe to classic ESM JavaScript or strict TypeScript/TSX",
			"#",
			"# This file is scaffold-managed by `mix haxe.phoenix.scaffold`. If you customize it, remove",
			"# the signature line above to opt out of future updates.",
			"# Pin provenance: " + PIN_NOTE + ".",
			"",
			"# @install: lix --silent download \"gh://github.com/fullofcaffeine/genes-ts#"
			+ COMMIT
			+ "\" into genes-ts/"
			+ VERSION
			+ "/github/"
			+ COMMIT,
			"-lib helder.set",
			"${HAXE_LIBCACHE}/genes-ts/" + VERSION + "/github/" + COMMIT + "/extraParams.hxml",
			"-cp ${HAXE_LIBCACHE}/genes-ts/" + VERSION + "/github/" + COMMIT + "/src",
			"-D genes-ts=" + VERSION
		]);
	}

	/** Render the transitional library name without introducing a second source. */
	public static function genesAliasHxml():String {
		return lines([
			"# " + GENES_ALIAS_SIGNATURE,
			"# Compatibility alias for projects that still use `-lib genes`.",
			"# Both names resolve the same immutable genes-ts revision.",
			"-lib genes-ts",
			"-D genes=" + VERSION
		]);
	}

	/** Render the classic ESM Phoenix client build owned by the scaffold. */
	public static function buildClientHxml():String {
		return lines([
			"# " + BUILD_CLIENT_SIGNATURE,
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
		]);
	}

	/**
	 * Migrate only scaffold-owned or historically exact browser build files.
	 *
	 * An unowned custom file keeps its content. The one historic safe migration
	 * remains supported: a conventional direct `hx_app.js` output is redirected
	 * to the temporary output consumed by the atomic promotion watcher.
	 */
	public static function patchBuildClientHxml(content:String):String {
		var normalized = normalize(content);
		return ownedEither(content, BUILD_CLIENT_SIGNATURE, LEGACY_BUILD_CLIENT_SIGNATURE, "build-client.hxml")
			|| normalized == normalize(legacyVendoredBuildClientHxml("assets/js/_hx_app_tmp.js"))
			|| normalized == normalize(legacyVendoredBuildClientHxml("assets/js/hx_app.js")) ? buildClientHxml() : ElixirString.contains(content,
				"assets/js/_hx_app_tmp.js") ? content : ElixirString.contains(content,
				"-js assets/js/hx_app.js") ? ElixirString.replace(content, "-js assets/js/hx_app.js", "-js assets/js/_hx_app_tmp.js") : content;
	}

	/** True only for a scaffold-owned or exact historic browser build file. */
	public static function managedBuildClientHxml(content:String):Bool {
		var normalized = normalize(content);
		return ownedEither(content, BUILD_CLIENT_SIGNATURE, LEGACY_BUILD_CLIENT_SIGNATURE, "build-client.hxml")
			|| normalized == normalize(legacyVendoredBuildClientHxml("assets/js/_hx_app_tmp.js"))
			|| normalized == normalize(legacyVendoredBuildClientHxml("assets/js/hx_app.js"));
	}

	/** Upgrade the old vendored `genes` descriptor without touching custom files. */
	public static function patchGenesAliasHxml(content:String):String {
		return ownedEither(content, GENES_ALIAS_SIGNATURE, LEGACY_GENES_ALIAS_SIGNATURE, "haxe_libraries/genes.hxml") ? genesAliasHxml() : content;
	}

	/** Recognize both current and legacy scaffold ownership for safe removal. */
	public static function managedGenesAliasHxml(content:String):Bool {
		return ownedEither(content, GENES_ALIAS_SIGNATURE, LEGACY_GENES_ALIAS_SIGNATURE, "haxe_libraries/genes.hxml");
	}

	/** Refresh the exact upstream pin only when the canonical descriptor is owned. */
	public static function patchGenesTsHxml(content:String):String {
		return ownedSignature(content, GENES_TS_SIGNATURE, "haxe_libraries/genes-ts.hxml") ? genesTsHxml() : content;
	}

	/** Recognize the canonical scaffold-owned dependency descriptor. */
	public static function managedGenesTsHxml(content:String):Bool {
		return ownedSignature(content, GENES_TS_SIGNATURE, "haxe_libraries/genes-ts.hxml");
	}

	static function ownedSignature(content:String, signature:String, label:String):Bool {
		var status = ProjectPatchApi.signatureStatus(content, signature);
		return Kernel.strictEqual(status,
			OWNED) ? true : Kernel.strictEqual(status,
			UNOWNED) ? false : Kernel.raiseValue("duplicate scaffold ownership signature in " + label + ": " + Kernel.inspect(status));
	}

	static function ownedEither(content:String, currentSignature:String, legacySignature:String, label:String):Bool {
		var currentOwned = ownedSignature(content, currentSignature, label);
		var legacyOwned = ownedSignature(content, legacySignature, label);
		return currentOwned || legacyOwned;
	}

	static function normalize(content:String):String {
		return ElixirString.trim(ElixirString.replace(content, "\r\n", "\n"));
	}

	/** Exact pre-genes-ts scaffold output retained solely for safe migration. */
	static function legacyVendoredBuildClientHxml(output:String):String {
		return lines([
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
			"-js " + output,
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
		]);
	}

	static function lines(values:Array<String>):String {
		return Enum.join(values, "\n") + "\n";
	}
}
