package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EndpointSocketMeta;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * Generates the framework-neutral Phoenix surface for JSON and Channels apps.
 *
 * WHAT
 * Emits the endpoint and web helper required by Phoenix JSON routes and
 * Channels when `-D phoenix_api_only` is present.
 *
 * WHY
 * The normal Phoenix generator intentionally includes LiveView, HTML,
 * Gettext, layouts, static assets, and cookie sessions. A service that exposes
 * only JSON routes and Channels must not need those optional packages merely
 * to compile its generated endpoint and web helper.
 *
 * HOW
 * The existing endpoint and Phoenix-web passes select this transform for the
 * complete build. It constructs only typed `ElixirAST` nodes. The default
 * path remains the full Phoenix transform. A socket with `session: true` adds
 * one shared session attribute and plug; omitted or false values add neither.
 *
 * EXAMPLES
 * Haxe:
 * ```haxe
 * @:endpointSockets([{path: "/socket", socket: UserSocket}])
 * @:endpoint class Endpoint {}
 * ```
 * Generated Elixir:
 * ```elixir
 * use Phoenix.Endpoint, otp_app: :my_app
 * socket "/socket", MyAppWeb.UserSocket, websocket: true, longpoll: false
 * plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], ...
 * plug MyAppWeb.Router
 * ```
 *
 * TESTS
 * - `test/snapshot/phoenix/api_only_profile`
 * - `test/snapshot/phoenix/api_only_session_socket`
 * - `test/snapshot/phoenix/api_only_implicit_web_default`
 *
 * LIMITS
 * This transform does not provide Phoenix dependencies, client code, HTML,
 * LiveView, static assets, or a general feature-profile system. It does not
 * change output when the define is absent.
 */
class PhoenixApiOnlyTransforms {
	/** Return true only for an explicitly selected API-only Phoenix build. */
	public static function enabled():Bool
		return Context.defined("phoenix_api_only");

	/** Replace one `@:endpoint` module with its API and Channels infrastructure. */
	public static function endpoint(ast:ElixirAST):ElixirAST {
		return switch ast.def {
			case EModule(name, attrs, _):
				makeASTWithMeta(EModule(name, attrs, endpointStatements(name, ast.metadata)), ast.metadata, ast.pos);
			case EDefmodule(name, _):
				makeASTWithMeta(EDefmodule(name, makeAST(EBlock(endpointStatements(name, ast.metadata)))), ast.metadata, ast.pos);
			default:
				ast;
		};
	}

	/** Replace one `@:phoenixWebModule` with JSON, router, and Channel helpers. */
	public static function web(ast:ElixirAST):ElixirAST {
		return switch ast.def {
			case EModule(name, attrs, body):
				makeASTWithMeta(EModule(name, attrs, webStatements(name, makeAST(EBlock(body)))), ast.metadata, ast.pos);
			case EDefmodule(name, body):
				makeASTWithMeta(EDefmodule(name, makeAST(EBlock(webStatements(name, body)))), ast.metadata, ast.pos);
			default:
				ast;
		};
	}

	static function endpointStatements(moduleName:String, metadata:ElixirMetadata):Array<ElixirAST> {
		final appName = metadata.appName != null ? metadata.appName : AnnotationTransforms.extractAppName(moduleName);
		final sockets:Array<EndpointSocketMeta> = metadata.endpointSockets == null ? [] : metadata.endpointSockets;
		final needsSession = hasSessionSocket(sockets);
		final statements:Array<ElixirAST> = [
			makeAST(EUse("Phoenix.Endpoint", [makeAST(EKeywordList([{key: "otp_app", value: makeAST(EAtom(appName))}]))]))
		];

		if (needsSession)
			statements.push(makeAST(EModuleAttribute("session_options", sessionOptions(appName))));

		for (socket in sockets) {
			final websocket = socket.session == true ? makeAST(EKeywordList([
				{key: "connect_info", value: makeAST(EKeywordList([{key: "session", value: makeAST(EVar("@session_options"))}]))}
			])) : makeAST(EBoolean(true));
			statements.push(makeAST(ECall(null, "socket", [
				makeAST(EString(socket.path)),
				makeAST(EVar(socket.socket)),
				makeAST(EKeywordList([
					{key: "websocket", value: websocket},
					{key: "longpoll", value: makeAST(EBoolean(false))}
				]))
			])));
		}

		statements.push(makeAST(EIf(makeAST(EVar("code_reloading?")), makeAST(ECall(null, "plug", [makeAST(EVar("Phoenix.CodeReloader"))])), null)));
		statements.push(makeAST(ECall(null, "plug", [makeAST(EVar("Plug.RequestId"))])));
		statements.push(makeAST(ECall(null, "plug", [
			makeAST(EVar("Plug.Telemetry")),
			makeAST(EKeywordList([
				{
					key: "event_prefix",
					value: makeAST(EList([
						makeAST(EAtom(ElixirAtom.raw("phoenix"))),
						makeAST(EAtom(ElixirAtom.raw("endpoint")))
					]))
				}
			]))
		])));
		statements.push(makeAST(ECall(null, "plug", [
			makeAST(EVar("Plug.Parsers")),
			makeAST(EKeywordList([
				{
					key: "parsers",
					value: makeAST(EList([
						makeAST(EAtom(ElixirAtom.raw("urlencoded"))),
						makeAST(EAtom(ElixirAtom.raw("multipart"))),
						makeAST(EAtom(ElixirAtom.raw("json")))
					]))
				},
				{key: "pass", value: makeAST(EList([makeAST(EString("*/*"))]))},
				{key: "json_decoder", value: makeAST(ERemoteCall(makeAST(EVar("Phoenix")), "json_library", []))}
			]))
		])));
		statements.push(makeAST(ECall(null, "plug", [makeAST(EVar("Plug.MethodOverride"))])));
		statements.push(makeAST(ECall(null, "plug", [makeAST(EVar("Plug.Head"))])));
		if (needsSession)
			statements.push(makeAST(ECall(null, "plug", [makeAST(EVar("Plug.Session")), makeAST(EVar("@session_options"))])));
		statements.push(makeAST(ECall(null, "plug", [makeAST(EVar(StringTools.replace(moduleName, ".Endpoint", ".Router")))])));
		return statements;
	}

	static function webStatements(moduleName:String, existingBody:ElixirAST):Array<ElixirAST> {
		final statements:Array<ElixirAST> = [];
		final definitions:Map<String, Bool> = [];
		appendExisting(statements, definitions, existingBody);

		if (!definitions.exists("__using__/1")) {
			final body = makeAST(ECall(null, "apply", [makeAST(EVar("__MODULE__")), makeAST(EVar("which")), makeAST(EList([]))]));
			statements.push(makeAST(EDefmacro("__using__", [EPattern.PVar("which")], makeAST(ECall(null, "is_atom", [makeAST(EVar("which"))])), body)));
		}

		if (!definitions.exists("router/0")) {
			final quoted = makeAST(EQuote([], makeAST(EBlock([
				makeAST(EUse("Phoenix.Router", [])),
				makeAST(EImport(moduleName, null, [{name: "controller", arity: 0}])),
				makeAST(ECall(null, "unquote", [makeAST(ECall(null, "verified_routes", []))]))
			]))));
			statements.push(makeAST(EDef("router", [], null, quoted)));
		}

		if (!definitions.exists("controller/0")) {
			final quoted = makeAST(EQuote([], makeAST(EBlock([
				makeAST(EUse("Phoenix.Controller", [
					makeAST(EKeywordList([
						{key: "formats", value: makeAST(EList([makeAST(EAtom(ElixirAtom.raw("json")))]))}
					]))
				])),
				makeAST(EImport("Plug.Conn", null, null)),
				makeAST(ECall(null, "unquote", [makeAST(ECall(null, "verified_routes", []))]))
			]))));
			statements.push(makeAST(EDef("controller", [], null, quoted)));
		}

		if (!definitions.exists("verified_routes/0")) {
			final quoted = makeAST(EQuote([], makeAST(EBlock([
				makeAST(EUse("Phoenix.VerifiedRoutes", [
					makeAST(EKeywordList([
						{key: "endpoint", value: makeAST(EVar(moduleName + ".Endpoint"))},
						{key: "router", value: makeAST(EVar(moduleName + ".Router"))},
						{key: "statics", value: makeAST(ERemoteCall(makeAST(EVar(moduleName)), "static_paths", []))}
					]))
				]))
			]))));
			statements.push(makeAST(EDef("verified_routes", [], null, quoted)));
		}

		if (!definitions.exists("channel/0")) {
			final quoted = makeAST(EQuote([], makeAST(EBlock([makeAST(EUse("Phoenix.Channel", []))]))));
			statements.push(makeAST(EDef("channel", [], null, quoted)));
		}

		if (!definitions.exists("static_paths/0"))
			statements.push(makeAST(EDef("static_paths", [], null, makeAST(EList([])))));
		return statements;
	}

	static function appendExisting(statements:Array<ElixirAST>, definitions:Map<String, Bool>, body:ElixirAST):Void {
		final existing = switch body.def {
			case EBlock(values): values;
			default: [body];
		};
		for (statement in existing) {
			if (statement.def == ENil)
				continue;
			statements.push(statement);
			switch statement.def {
				case EDef(name, args, _, _):
					definitions.set(name + "/" + args.length, true);
				case EDefp(name, args, _, _):
					definitions.set(name + "/" + args.length, true);
				case EDefmacro(name, args, _, _):
					definitions.set(name + "/" + args.length, true);
				case _:
			}
		}
	}

	static function hasSessionSocket(sockets:Array<EndpointSocketMeta>):Bool {
		for (socket in sockets)
			if (socket.session == true)
				return true;
		return false;
	}

	static function sessionOptions(appName:String):ElixirAST
		return makeAST(EKeywordList([
			{key: "store", value: makeAST(EAtom(ElixirAtom.raw("cookie")))},
			{key: "key", value: makeAST(EString('_${appName}_key'))},
			{key: "signing_salt", value: makeAST(EString('${appName}_signing_salt'))},
			{key: "same_site", value: makeAST(EString("Lax"))}
		]));
}
#end
