package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.PhoenixContext;

using StringTools;

/** Exact semantic ownership used to decide whether a configured AST pass is relevant. */
enum abstract PassScope(String) from String to String {
	var Core = "core";
	var Stdlib = "stdlib";
	var Phoenix = "phoenix";
	var LiveView = "liveview";
	var Ecto = "ecto";
	var Hxx = "hxx";
	var ExUnit = "exunit";
	var Diagnostics = "diagnostics";
	var Mixed = "mixed";
}

/** Read-only module facts recomputed at phase boundaries as the AST gains target structure. */
typedef PassCapabilities = {
	var phoenix:Bool;
	var liveView:Bool;
	var ecto:Bool;
	var hxx:Bool;
	var exunit:Bool;
}

/**
 * Computes typed module capabilities for pass applicability.
 *
 * WHAT
 * - Identifies whether the current module can require Phoenix/OTP, LiveView,
 *   Ecto, HXX/HEEx, or ExUnit transforms.
 *
 * WHY
 * - Framework passes are expensive full-tree walks and are irrelevant to most
 *   core modules. Skipping them must not create a second semantic pipeline.
 *
 * HOW
 * - Reads Haxe annotations retained in `CompilationContext`, compiler-only
 *   `ElixirMetadata`, and structured target nodes. Exact `Phoenix.*`, `Ecto.*`,
 *   and `ExUnit.*` references are real target API boundaries, not generated app
 *   or file-name heuristics. The runner recomputes these facts at phase
 *   boundaries so an earlier phase can expose a capability needed later.
 * - Phoenix/OTP modules remain conservatively eligible for Ecto passes because
 *   framework lowering can produce unqualified Repo shapes within those modules.
 * - `reflaxe_elixir_disable_pass_scopes` is a verification-only switch used to
 *   compare this path with legacy all-pass execution.
 *
 * EXAMPLE
 * - A plain core module skips LiveView passes. A `@:liveview` module enables
 *   LiveView, Phoenix, and HXX capabilities before annotation lowering begins.
 */
class PassApplicability {
	public static function analyze(ast:ElixirAST, ?context:reflaxe.elixir.CompilationContext):PassCapabilities {
		var capabilities:PassCapabilities = {
			phoenix: false,
			liveView: false,
			ecto: false,
			hxx: false,
			exunit: false
		};
		if (context != null && context.currentClass != null) {
			var classMetadata = context.currentClass.meta;
			capabilities.liveView = classMetadata.has(":liveview") || classMetadata.has(":presence");
			capabilities.phoenix = capabilities.liveView
				|| classMetadata.has(":endpoint")
				|| classMetadata.has(":router")
				|| classMetadata.has(":controller")
				|| classMetadata.has(":channel")
				|| classMetadata.has(":socket")
				|| classMetadata.has(":phoenixWeb")
				|| classMetadata.has(":phoenixWebModule")
				|| classMetadata.has(":application")
				|| classMetadata.has(":supervisor")
				|| classMetadata.has(":genserver")
				|| classMetadata.has(":gettext");
			capabilities.ecto = classMetadata.has(":schema") || classMetadata.has(":repo") || classMetadata.has(":migration")
				|| classMetadata.has(":query") || classMetadata.has(":changeset") || classMetadata.has(":postgrexTypes") || classMetadata.has(":dbTypes");
			capabilities.exunit = classMetadata.has(":exunit") || classMetadata.has("exunit");
			capabilities.hxx = capabilities.liveView
				|| classMetadata.has(":component")
				|| classMetadata.has(":hxx_inline_markup")
				|| classMetadata.has(":hxx_mode");
		}

		ASTUtils.walk(ast, function(node:ElixirAST):Void {
			var metadata = node.metadata;
			if (metadata != null) {
				var isLiveView = metadata.isLiveView == true
					|| metadata.isPresence == true
					|| metadata.phoenixContext == PhoenixContext.LiveView;
				if (isLiveView) {
					capabilities.liveView = true;
					capabilities.phoenix = true;
				}
				if (metadata.isEndpoint == true || metadata.isRouter == true || metadata.isController == true || metadata.isPhoenixWeb == true
					|| metadata.isSocket == true || metadata.isApplication == true || metadata.isSupervisor == true || metadata.isGenServer == true
					|| metadata.phoenixContext != null) {
					capabilities.phoenix = true;
				}
				if (metadata.isSchema == true || metadata.isRepo == true || metadata.isPostgrexTypes == true || metadata.isDbTypes == true
					|| metadata.ectoContext != null) {
					capabilities.ecto = true;
				}
				if (metadata.isExunit == true)
					capabilities.exunit = true;
				if (metadata.usesHxx == true
					|| (metadata.heexFragments != null && metadata.heexFragments.length > 0)
					|| (metadata.heexAST != null && metadata.heexAST.length > 0))
					capabilities.hxx = true;
				markFrameworkModule(metadata.nativeModule, capabilities);
			}

			switch (node.def) {
				case EUse(module, _) | EImport(module, _, _, _) | ERequire(module, _):
					markFrameworkModule(module, capabilities);
				case ERemoteCall(module, _, _):
					switch (module.def) {
						case EVar(name) | EAlias(name, _):
							markFrameworkModule(name, capabilities);
						default:
					}
				case ESigil(type, _, _) if (type == "H"):
					capabilities.hxx = true;
				case EFragment(_, _, _) | EAssign(_):
					capabilities.hxx = true;
				case EDef(_, args, _, _) | EDefp(_, args, _, _):
					for (arg in args)
						switch (arg) {
							case PVar("assigns"): capabilities.hxx = true;
							default:
						}
				default:
			}
		});

		if (capabilities.liveView)
			capabilities.hxx = true;
		return capabilities;
	}

	public static inline function shouldRun(scope:Null<PassScope>, capabilities:PassCapabilities):Bool {
		#if reflaxe_elixir_disable_pass_scopes
		return true;
		#else
		return applies(scope, capabilities);
		#end
	}

	public static function applies(scope:Null<PassScope>, capabilities:PassCapabilities):Bool {
		if (scope == null)
			return true;
		return switch (scope) {
			case Phoenix: capabilities.phoenix;
			case LiveView: capabilities.liveView;
			case Ecto: capabilities.ecto || capabilities.phoenix;
			case Hxx: capabilities.hxx;
			case ExUnit: capabilities.exunit;
			case Core | Stdlib | Diagnostics | Mixed: true;
			default: true;
		};
	}

	static function markFrameworkModule(module:Null<String>, capabilities:PassCapabilities):Void {
		if (module == null || module.length == 0)
			return;
		if (module == "Phoenix" || module.startsWith("Phoenix."))
			capabilities.phoenix = true;
		if (module == "Phoenix.LiveView" || module.startsWith("Phoenix.LiveView.")) {
			capabilities.liveView = true;
			capabilities.hxx = true;
		}
		if (module == "Ecto" || module.startsWith("Ecto."))
			capabilities.ecto = true;
		if (module == "ExUnit" || module.startsWith("ExUnit."))
			capabilities.exunit = true;
	}
}
#end
