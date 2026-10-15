package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * WHAT: Adds the standard Plug call override for a typed endpoint admission callback.
 *
 * WHY: Ordinary endpoint plugs run after Phoenix's built-in SSL and socket plugs.
 * HOW: The override instead calls the authored method, returns a halted connection,
 * or invokes the original pipeline with `super`. Phoenix's own before-compile
 * callback still wraps this entry point with endpoint setup and error handling.
 *
 * EXAMPLES: For `@:endpointAdmission static function admit(conn:Conn<{}>):Conn<{}>`, emit
 * `def call(conn, opts)` with `conn = admit(conn)` and the halt/super branch.
 * Retain the existing Haxe methods so the callback can call ordinary helpers.
 * Endpoints without this annotation keep their existing generated shape.
 */
class EndpointAdmissionTransforms {
	/** Append one wrapper and the authored body; never silently drop the selected method. */
	public static function append(statements:Array<ElixirAST>, authored:ElixirAST, metadata:ElixirMetadata):Void {
		final callback = metadata.endpointAdmission;
		if (callback == null)
			return;

		final definitions = switch authored.def {
			case EBlock(values): values;
			default: [authored];
		};
		var found = false;
		for (definition in definitions) {
			switch definition.def {
				case EDef(name, args, _, _) | EDefp(name, args, _, _):
					// Defaults emit lower arities too: call(conn, opts, ?extra) owns call/2.
					final defaults = definition.metadata.functionArgDefaults;
					final minimumArity = args.length - (defaults == null ? 0 : defaults.length);
					if (name == "call" && minimumArity <= 2 && args.length >= 2)
						Context.error("An endpoint with @:endpointAdmission cannot also define call/2", definition.pos);
					if (name == callback && args.length == 1)
						found = true;
				default:
			}
		}
		if (!found)
			Context.error("The selected @:endpointAdmission method was not emitted", authored.pos);

		final conn = makeAST(EVar("conn"));
		final opts = makeAST(EVar("opts"));
		statements.push(makeAST(EDef("call", [PVar("conn"), PVar("opts")], null, makeAST(EBlock([
			makeAST(EMatch(PVar("conn"), makeAST(ECall(null, callback, [conn])))),
			makeAST(EIf(makeAST(EField(conn, "halted")), conn, makeAST(ECall(null, "super", [conn, opts]))))
		])))));
		for (definition in definitions)
			if (definition.def != ENil)
				statements.push(definition);
	}
}
#end
