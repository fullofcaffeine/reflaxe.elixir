package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Typed pipeline-name token used by router DSL calls.
 *
 * WHY
 * - Prevents accidental raw-string API usage in typed router nodes.
 * - Keeps pipeline refs finite and completion-friendly.
 *
 * HOW
 * - Built-in names are exposed as constants (`browser`, `api`).
 * - Custom names can be created with `pipelineName("custom_name")`.
 */
abstract PipelineName(String) to String {}

/**
 * Typed plug-name token for atom-style `plug :name` entries.
 *
 * WHY
 * - Avoids weak `String` parameters for plug atoms in typed router APIs.
 *
 * HOW
 * - Built-in names are exposed as constants (`accepts`, `fetch_session`, ...).
 * - Custom names can be created with `plugName("my_plug")`.
 */
abstract PlugName(String) to String {}

/**
 * Typed Phoenix resource action token for `resources(..., {only: ...})` and
 * `resources(..., {except: ...})`.
 *
 * WHY
 * - Phoenix resource actions are a fixed set (`:index`, `:show`, etc.).
 * - A typed token gives autocomplete and catches misspellings earlier than Elixir compilation.
 *
 * HOW
 * - Prefer the `resourceIndex`, `resourceShow`, ... constants from `RouterDsl`.
 * - Existing string literals such as `"index"` stay source-compatible, but are checked at
 *   compile time and converted into this token type.
 */
abstract ResourceAction(String) to String {
	#if macro
	static function validateLiteral(expr:ExprOf<String>):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				var isValid = switch (value) {
					case "index" | "show" | "new" | "create" | "edit" | "update" | "delete":
						true;
					default:
						false;
				}
				if (!isValid) {
					Context.error('Resource action must be one of: "index", "show", "new", "create", "edit", "update", "delete".', expr.pos);
				}
				value;
			default:
				Context.error("Resource action compatibility values must be string literals. Use RouterDsl resource-action constants for new code.", expr.pos);
				null;
		};
	}
	#end

	@:from
	public static macro function fromStringLiteral(value:ExprOf<String>):ExprOf<ResourceAction> {
		#if macro
		var actionValue = validateLiteral(value);
		return macro(cast($v{actionValue} : String) : reflaxe.elixir.macros.ResourceAction);
		#else
		return null;
		#end
	}
}

/**
 * Typed plug target token.
 *
 * Supports:
 * - plug atoms (`PlugName`) => `plug :fetch_session`
 * - plug modules (`Class<Any>`) => `plug MyAppWeb.SomePlug`
 */
abstract PlugTarget(Any) {
	@:from
	public static inline function fromPlugName(value:PlugName):PlugTarget {
		return cast value;
	}

	@:from
	public static inline function fromModuleRef(value:Class<Any>):PlugTarget {
		return cast value;
	}
}

/**
 * Typed router DSL nodes for `@:routes([...])`.
 *
 * WHY
 * - `@:routes` started as a flat list of route objects.
 * - Phoenix routers are tree-shaped (pipeline/scope/live_session nesting).
 *
 * WHAT
 * - Provides typed Haxe constructors that model router structure directly.
 * - Values are parsed by compiler metadata extraction (ElixirCompiler).
 *
 * HOW
 * - Each constructor returns a small tagged node object.
 * - Parser matches `kind` + typed fields and lowers to Phoenix router macros.
 *
 * USAGE
 * - Prefer `import reflaxe.elixir.macros.RouterDsl.*;` so router defs can use
 *   `pipeline(...)`, `scope(...)`, `get(...)` without a `RouterDsl.` prefix.
 */
typedef RouterDslNode = {
	var kind:String;
	@:optional var name:String;
	@:optional var target:PlugTarget;
	@:optional var path:String;
	@:optional var children:Array<RouterDslNode>;
	@:optional var opts:Any;
	@:optional var pipelines:Array<PipelineName>;
	@:optional var method:String;
	@:optional var controller:Class<Any>;
	@:optional var action:Any;
	@:optional var verb:String;
	@:optional var moduleRef:Class<Any>;
}

typedef ScopeOptions = {
	@:optional var asName:String;
	@:optional var host:String;
	@:optional var privateData:{}; // maps to `private: ...`
	@:optional var assigns:{};
	@:optional var aliasModule:Class<Any>; // second scope argument
}

typedef RouteOptions = {
	@:optional var name:String; // helper override
	@:optional var asName:String;
	@:optional var host:String;
	@:optional var privateData:{};
	@:optional var assigns:{};
	@:optional var paramsContract:Class<Any>; // typedef/class used for path param validation
}

typedef MatchRouteOptions = {
	@:optional var name:String;
	@:optional var asName:String;
	@:optional var host:String;
	@:optional var privateData:{};
	@:optional var assigns:{};
	@:optional var paramsContract:Class<Any>;
}

typedef PipeThroughOptions = {
	@:optional var append:Bool; // reserved for future
}

typedef LiveSessionOptions = {
	@:optional var session:LiveSessionMfa; // e.g. {session: liveSessionMfa(MyAppWeb, "live_session")}
	@:optional var onMount:Array<OnMountHook>;
	@:optional var rootLayout:Any;
}

typedef LiveSessionMfa = {}
typedef OnMountHook = {}

typedef ResourceOptions = {
	@:optional var only:Array<ResourceAction>;
	@:optional var except:Array<ResourceAction>;
	@:optional var param:String;
	@:optional var asName:String;
	@:optional var singleton:Bool;
	@:optional var paramsContract:Class<Any>;
}

typedef ForwardOptions = {
	@:optional var asName:String;
	@:optional var host:String;
	@:optional var privateData:{};
	@:optional var assigns:{};
}

typedef PlugOptions = {
	@:optional var initArgs:Any;
}

typedef LiveDashboardOptions = {
	@:optional var metricsModule:Class<Any>;
	@:optional var envs:Array<String>; // default handled in transform when omitted
}

typedef MailboxOptions = {
	@:optional var mailboxModule:Class<Any>; // defaults to Plug.Swoosh.MailboxPreview
	@:optional var envs:Array<String>; // default handled in transform when omitted
}

class RouterDsl {
	// Default Phoenix pipelines.
	public static inline var browser:PipelineName = cast "browser";
	public static inline var api:PipelineName = cast "api";

	// Common Phoenix plug atoms.
	public static inline var accepts:PlugName = cast "accepts";
	public static inline var fetch_session:PlugName = cast "fetch_session";
	public static inline var fetch_live_flash:PlugName = cast "fetch_live_flash";
	public static inline var protect_from_forgery:PlugName = cast "protect_from_forgery";
	public static inline var put_secure_browser_headers:PlugName = cast "put_secure_browser_headers";
	public static inline var put_root_layout:PlugName = cast "put_root_layout";

	// Phoenix resource actions for `only` and `except`.
	public static inline var resourceIndex:ResourceAction = cast "index";
	public static inline var resourceShow:ResourceAction = cast "show";
	public static inline var resourceNew:ResourceAction = cast "new";
	public static inline var resourceCreate:ResourceAction = cast "create";
	public static inline var resourceEdit:ResourceAction = cast "edit";
	public static inline var resourceUpdate:ResourceAction = cast "update";
	public static inline var resourceDelete:ResourceAction = cast "delete";

	#if macro
	static function validateTypedAtomName(expr:ExprOf<String>, label:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				var isValid = ~/^[a-z_][a-z0-9_]*$/.match(value);
				if (!isValid) {
					Context.error('${label} must be snake_case (example: "fetch_session").', expr.pos);
				}
				value;
			default:
				Context.error('${label} must be a string literal.', expr.pos);
				null;
		};
	}
	#end

	/**
	 * Create a typed custom pipeline token from a literal (validated at compile time).
	 */
	public static macro function pipelineName(value:ExprOf<String>):ExprOf<PipelineName> {
		#if macro
		var pipelineValue = validateTypedAtomName(value, "pipelineName");
		return macro(cast($v{pipelineValue} : String) : reflaxe.elixir.macros.PipelineName);
		#else
		return null;
		#end
	}

	/**
	 * Create a typed custom plug atom token from a literal (validated at compile time).
	 */
	public static macro function plugName(value:ExprOf<String>):ExprOf<PlugName> {
		#if macro
		var plugValue = validateTypedAtomName(value, "plugName");
		return macro(cast($v{plugValue} : String) : reflaxe.elixir.macros.PlugName);
		#else
		return null;
		#end
	}

	/** `pipeline :name do ... end` */
	public static inline function pipeline(name:PipelineName, children:Array<RouterDslNode>):RouterDslNode {
		return {
			kind: "pipeline",
			name: name,
			children: children
		};
	}

	/**
	 * Escape hatch for legacy/raw pipeline names.
	 *
	 * Prefer `pipeline(browser, ...)` or `pipeline(pipelineName("custom"), ...)` in new code.
	 */
	public static inline function pipelineUnsafe(name:String, children:Array<RouterDslNode>):RouterDslNode {
		return {
			kind: "pipeline_unsafe",
			name: name,
			children: children
		};
	}

	/** `plug ...` inside pipeline */
	public static inline function plug(target:PlugTarget, ?opts:PlugOptions):RouterDslNode {
		return {
			kind: "plug",
			target: target,
			opts: opts
		};
	}

	/**
	 * Escape hatch for raw plug targets.
	 *
	 * Prefer typed `plug(accepts, ...)`, `plug(fetch_session)`, or `plug(MyPlugModule)`.
	 */
	public static inline function plugUnsafe(target:String, ?opts:PlugOptions):RouterDslNode {
		return {
			kind: "plug_unsafe",
			target: cast target,
			opts: opts
		};
	}

	/** `scope ... do ... end` */
	public static inline function scope(path:String, children:Array<RouterDslNode>, ?opts:ScopeOptions):RouterDslNode {
		return {
			kind: "scope",
			path: path,
			children: children,
			opts: opts
		};
	}

	/** `pipe_through ...` */
	public static inline function pipeThrough(pipelines:Array<PipelineName>, ?opts:PipeThroughOptions):RouterDslNode {
		return {
			kind: "pipe_through",
			pipelines: pipelines,
			opts: opts
		};
	}

	/**
	 * Escape hatch for raw `pipe_through` values.
	 *
	 * Prefer typed `pipeThrough([browser])` (or `pipelineName("custom")` for custom names).
	 */
	public static inline function pipeThroughUnsafe(pipelines:Array<String>, ?opts:PipeThroughOptions):RouterDslNode {
		return {
			kind: "pipe_through_unsafe",
			pipelines: cast pipelines,
			opts: opts
		};
	}

	/** `live_session ... do ... end` */
	public static inline function liveSession(name:String, children:Array<RouterDslNode>, ?opts:LiveSessionOptions):RouterDslNode {
		return {
			kind: "live_session",
			name: name,
			children: children,
			opts: opts
		};
	}

	/**
	 * Phoenix LiveView session MFA for `live_session`.
	 *
	 * Haxe source:
	 * ```haxe
	 * liveSession("default", [live("/", AppLive)], {
	 *   session: liveSessionMfa(MyAppWeb, "live_session")
	 * });
	 * ```
	 *
	 * Generated Elixir:
	 * ```elixir
	 * live_session :default, session: {MyAppWeb, :live_session, []} do
	 * ```
	 */
	public static inline function liveSessionMfa(moduleRef:Class<Any>, functionName:String, ?args:Array<Any>):LiveSessionMfa {
		return cast {};
	}

	/**
	 * Phoenix LiveView `on_mount` hook for `live_session`.
	 *
	 * Haxe source:
	 * ```haxe
	 * liveSession("default", [live("/", AppLive)], {
	 *   onMount: [onMount(AuthHook)]
	 * });
	 * ```
	 *
	 * Generated Elixir:
	 * ```elixir
	 * live_session :default, on_mount: [AuthHook] do
	 * ```
	 */
	public static inline function onMount(moduleRef:Class<Any>):OnMountHook {
		return cast {};
	}

	/**
	 * Phoenix LiveView `on_mount` hook with an argument tuple.
	 *
	 * Haxe source:
	 * ```haxe
	 * liveSession("admin", [live("/admin", AdminLive)], {
	 *   onMount: [onMountArg(AuthHook, "admin")]
	 * });
	 * ```
	 *
	 * Generated Elixir:
	 * ```elixir
	 * live_session :admin, on_mount: [{AuthHook, :admin}] do
	 * ```
	 */
	public static inline function onMountArg(moduleRef:Class<Any>, arg:String):OnMountHook {
		return cast {};
	}

	public static inline function get(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("GET", path, controller, action, opts);
	}

	public static inline function post(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("POST", path, controller, action, opts);
	}

	public static inline function put(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("PUT", path, controller, action, opts);
	}

	public static inline function patch(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("PATCH", path, controller, action, opts);
	}

	public static inline function delete(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("DELETE", path, controller, action, opts);
	}

	public static inline function options(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("OPTIONS", path, controller, action, opts);
	}

	public static inline function head(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("HEAD", path, controller, action, opts);
	}

	public static inline function connect(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("CONNECT", path, controller, action, opts);
	}

	public static inline function trace(path:String, controller:Class<Any>, action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("TRACE", path, controller, action, opts);
	}

	/**
	 * `live "/path", LiveModule, :action`
	 *
	 * The action is optional:
	 * - `live("/", AppLive)` emits `live "/", AppLive`
	 * - `live("/todos/:id", TodoLive, TodoLive.show)` emits `live "/todos/:id", TodoLive, :show`
	 *
	 * WHY
	 * - Phoenix allows live routes without an explicit action.
	 * - Requiring a placeholder action method in LiveView modules adds noise for simple routes.
	 */
	public static inline function live(path:String, liveModule:Class<Any>, ?action:Any, ?opts:RouteOptions):RouterDslNode {
		return route("LIVE", path, liveModule, action, opts);
	}

	/** `match :verb, "/path", Controller, :action` */
	public static inline function match(verb:HttpMethod, path:String, controller:Class<Any>, action:Any, ?opts:MatchRouteOptions):RouterDslNode {
		return {
			kind: "match",
			verb: Std.string(verb),
			path: path,
			controller: controller,
			action: action,
			opts: opts
		};
	}

	/** `forward "/path", SomePlugOrRouter` */
	public static inline function forward(path:String, moduleRef:Class<Any>, ?opts:ForwardOptions):RouterDslNode {
		return {
			kind: "forward",
			path: path,
			moduleRef: moduleRef,
			opts: opts
		};
	}

	/** `resources "/users", UserController, ...` */
	public static inline function resources(path:String, controller:Class<Any>, ?opts:ResourceOptions):RouterDslNode {
		return {
			kind: "resources",
			path: path,
			controller: controller,
			opts: opts
		};
	}

	/** `resource "/profile", ProfileController, ...` */
	public static inline function resource(path:String, controller:Class<Any>, ?opts:ResourceOptions):RouterDslNode {
		return {
			kind: "resource",
			path: path,
			controller: controller,
			opts: opts
		};
	}

	/** `live_dashboard "/dashboard", ...` */
	public static inline function liveDashboard(path:String, ?opts:LiveDashboardOptions):RouterDslNode {
		return {
			kind: "live_dashboard",
			path: path,
			opts: opts
		};
	}

	/** mailbox preview helper (typically `forward "/mailbox", Plug.Swoosh.MailboxPreview`) */
	public static inline function mailbox(path:String, ?opts:MailboxOptions):RouterDslNode {
		return {
			kind: "mailbox",
			path: path,
			opts: opts
		};
	}

	static inline function route(method:String, path:String, controller:Class<Any>, action:Any, opts:RouteOptions):RouterDslNode {
		return {
			kind: "route",
			method: method,
			path: path,
			controller: controller,
			action: action,
			opts: opts
		};
	}
}
#end
