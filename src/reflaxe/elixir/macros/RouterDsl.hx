package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
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
	@:optional var target:Any;
	@:optional var path:String;
	@:optional var children:Array<RouterDslNode>;
	@:optional var opts:Any;
	@:optional var pipelines:Array<String>;
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
	@:optional var session:{}; // e.g. {session: {MyAppWeb, :live_session, []}}
	@:optional var onMount:Array<Any>;
	@:optional var rootLayout:Any;
}

typedef ResourceOptions = {
	@:optional var only:Array<String>;
	@:optional var except:Array<String>;
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
	/** `pipeline :name do ... end` */
	public static inline function pipeline(name:String, children:Array<RouterDslNode>):RouterDslNode {
		return {
			kind: "pipeline",
			name: name,
			children: children
		};
	}

	/** `plug ...` inside pipeline */
	public static inline function plug(target:Any, ?opts:PlugOptions):RouterDslNode {
		return {
			kind: "plug",
			target: target,
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
	public static inline function pipeThrough(pipelines:Array<String>, ?opts:PipeThroughOptions):RouterDslNode {
		return {
			kind: "pipe_through",
			pipelines: pipelines,
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
