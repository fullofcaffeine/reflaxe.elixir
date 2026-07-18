package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * ExUnitAssertTransforms
 *
 * WHAT
 * - Rewrites calls to `haxe.test.Assert.*` into idiomatic ExUnit assertions inside ExUnit modules.
 * - Eliminates runtime stub calls that intentionally throw (the stdlib Assert implementation).
 *
 * WHY
 * - `haxe.test.Assert` functions are placeholders in stdlib and are intended to be compiled away.
 * - Without this pass, Haxe-authored ExUnit tests compile but fail at runtime with
 *   `"Assert.* should be compiled by ExUnitCompiler"`.
 *
 * HOW
 * - Detect ExUnit modules by metadata (`isExunit`) or presence of `use ExUnit.Case`.
 * - Inside those modules, rewrite `Assert.*` remote calls:
 *   - `Assert.equals(a, b, msg)` -> `assert(a == b, msg?)`
 *   - `Assert.is_true(v, msg)` -> `assert(v, msg?)`
 *   - `Assert.is_false(v, msg)` -> `refute(v, msg?)`
 *   - `Assert.raises(fn, ex, msg)` -> `assert_raise(ex, msg?, fn)` (when `ex` provided)
 *     or `assert(try ... rescue ... end)` (when `ex` is nil)
 *   - `Assert.raisesRuntimeErrorMatching(fn, pattern)` ->
 *     `assert_raise(RuntimeError, Regex.compile!(pattern), fn)`
 *   - plus other common assertion helpers.
 *
 * EXAMPLES
 * Haxe:
 *   @:test function ok() {
 *     Assert.equals(1, 1);
 *     Assert.isFalse(false);
 *     Assert.raises(() -> throw "boom");
 *   }
 *
 * Elixir (before):
 *   _ = Assert.equals(1, 1, nil)
 *
 * Elixir (after):
 *   assert(1 == 1)
 */
class ExUnitAssertTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDefmodule(name, body) if (isExUnitModule(n, body)):
					makeASTWithMeta(EDefmodule(name, rewriteAssertCalls(body)), n.metadata, n.pos);
				case EModule(name, attrs, bodyExprs) if (isExUnitModule(n, makeAST(EBlock(bodyExprs)))):
					var rewritten = rewriteAssertCalls(makeAST(EBlock(bodyExprs)));
					var exprs = switch (rewritten.def) {
						case EBlock(es): es;
						case _: bodyExprs;
					};
					makeASTWithMeta(EModule(name, attrs, exprs), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function rewriteAssertCalls(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case ERemoteCall(mod, fnName, args) if (isAssertModule(mod)):
					rewriteAssertRemoteCall(n, fnName, args);
				case ECall({def: EVar("Assert")}, fnName, args):
					rewriteAssertRemoteCall(n, fnName, args);
				default:
					n;
			}
		});
	}

	static function rewriteAssertRemoteCall(n:ElixirAST, fnName:String, args:Array<ElixirAST>):ElixirAST {
		return switch (fnName) {
			case "is_true":
				if (args == null || args.length < 1) n else assertOrRefute("assert", args[0], takeOptionalNonNilArg(args, 1), n);
			case "is_false":
				if (args == null || args.length < 1) n else assertOrRefute("refute", args[0], takeOptionalNonNilArg(args, 1), n);
			case "equals":
				if (args == null || args.length < 2) n else assertOrRefute("assert", makeAST(EBinary(EBinaryOp.Equal, args[0], args[1])),
					takeOptionalNonNilArg(args, 2), n);
			case "not_equals":
				if (args == null || args.length < 2) n else assertOrRefute("assert", makeAST(EBinary(EBinaryOp.NotEqual, args[0], args[1])),
					takeOptionalNonNilArg(args, 2), n);
			case "is_null":
				if (args == null || args.length < 1) n else assertOrRefute("assert", makeAST(ECall(null, "is_nil", [args[0]])),
					takeOptionalNonNilArg(args, 1), n);
			case "is_not_null":
				if (args == null || args.length < 1) n else assertOrRefute("refute", makeAST(ECall(null, "is_nil", [args[0]])),
					takeOptionalNonNilArg(args, 1), n);
			case "is_some":
				if (args == null || args.length < 1) n else assertOrRefute("assert", optionIsSomeExpr(args[0]), takeOptionalNonNilArg(args, 1), n);
			case "is_none":
				if (args == null || args.length < 1) n else assertOrRefute("assert", optionIsNoneExpr(args[0]), takeOptionalNonNilArg(args, 1), n);
			case "is_ok":
				if (args == null || args.length < 1) n else assertOrRefute("assert", resultIsOkExpr(args[0]), takeOptionalNonNilArg(args, 1), n);
			case "is_error":
				if (args == null || args.length < 1) n else assertOrRefute("assert", resultIsErrorExpr(args[0]), takeOptionalNonNilArg(args, 1), n);
			case "raises":
				rewriteRaises(n, args);
			case "raises_runtime_error_matching":
				rewriteRuntimeErrorMatching(n, args);
			case "does_not_raise":
				rewriteDoesNotRaise(n, args);
			case "contains":
				if (args == null || args.length < 2) n else assertOrRefute("assert",
					makeAST(ERemoteCall(makeAST(EVar("Enum")), "member?", [args[0], args[1]])), takeOptionalNonNilArg(args, 2), n);
			case "contains_string":
				if (args == null || args.length < 2) n else assertOrRefute("assert",
					makeAST(ERemoteCall(makeAST(EVar("String")), "contains?", [args[0], args[1]])), takeOptionalNonNilArg(args, 2), n);
			case "does_not_contain_string":
				if (args == null || args.length < 2) n else assertOrRefute("refute",
					makeAST(ERemoteCall(makeAST(EVar("String")), "contains?", [args[0], args[1]])), takeOptionalNonNilArg(args, 2), n);
			case "is_empty":
				if (args == null || args.length < 1) n else assertOrRefute("assert", makeAST(ERemoteCall(makeAST(EVar("Enum")), "empty?", [args[0]])),
					takeOptionalNonNilArg(args, 1), n);
			case "is_not_empty":
				if (args == null || args.length < 1) n else assertOrRefute("refute", makeAST(ERemoteCall(makeAST(EVar("Enum")), "empty?", [args[0]])),
					takeOptionalNonNilArg(args, 1), n);
			case "in_delta":
				rewriteInDelta(n, args);
			case "fail":
				if (args == null || args.length < 1) n else makeASTWithMeta(ECall(null, "flunk", [args[0]]), n.metadata, n.pos);
			case "matches":
				if (args == null || args.length < 2) n else assertOrRefute("assert", makeAST(ECall(null, "match?", [args[0], args[1]])),
					takeOptionalNonNilArg(args, 2), n);
			case "received":
				rewriteReceived(n, args);
			default:
				n;
		}
	}

	static function rewriteRaises(n:ElixirAST, args:Array<ElixirAST>):ElixirAST {
		if (args == null || args.length < 1)
			return n;
		var fnExpr = args[0];
		var exceptionModule = takeOptionalNonNilArg(args, 1);
		var message = takeOptionalNonNilArg(args, 2);

		if (exceptionModule != null) {
			var assertArgs = [];
			assertArgs.push(exceptionModule);
			if (message != null)
				assertArgs.push(message);
			assertArgs.push(fnExpr);
			return makeASTWithMeta(ECall(null, "assert_raise", assertArgs), n.metadata, n.pos);
		}

		// Any exception: assert(try do fn.(); false rescue _ -> true end, msg?)
		var didRaiseExpr = tryRescueBoolean(fnExpr, false, true);
		return assertOrRefute("assert", didRaiseExpr, message, n);
	}

	static function rewriteRuntimeErrorMatching(n:ElixirAST, args:Array<ElixirAST>):ElixirAST {
		if (args == null || args.length < 2)
			return n;
		var regex = makeAST(ERemoteCall(makeAST(EVar("Regex")), "compile!", [args[1]]));
		return makeASTWithMeta(ECall(null, "assert_raise", [makeAST(EVar("RuntimeError")), regex, args[0]]), n.metadata, n.pos);
	}

	static function rewriteDoesNotRaise(n:ElixirAST, args:Array<ElixirAST>):ElixirAST {
		if (args == null || args.length < 1)
			return n;
		var fnExpr = args[0];
		var message = takeOptionalNonNilArg(args, 1);

		// Without a message, "just run it" is strictly better: any raise already fails the test.
		if (message == null) {
			return makeASTWithMeta(ECall(fnExpr, "", []), n.metadata, n.pos);
		}

		var didNotRaiseExpr = tryRescueBoolean(fnExpr, true, false);
		return assertOrRefute("assert", didNotRaiseExpr, message, n);
	}

	static function rewriteInDelta(n:ElixirAST, args:Array<ElixirAST>):ElixirAST {
		if (args == null || args.length < 3)
			return n;
		var message = takeOptionalNonNilArg(args, 3);
		var assertArgs = [args[0], args[1], args[2]];
		if (message != null)
			assertArgs.push(message);
		return makeASTWithMeta(ECall(null, "assert_in_delta", assertArgs), n.metadata, n.pos);
	}

	static function rewriteReceived(n:ElixirAST, args:Array<ElixirAST>):ElixirAST {
		if (args == null || args.length < 1)
			return n;
		var pattern = args[0];
		var timeout = takeOptionalNonNilArg(args, 1);
		var message = takeOptionalNonNilArg(args, 2);

		var callArgs = [pattern];
		if (timeout != null)
			callArgs.push(timeout);
		if (message != null) {
			if (timeout == null)
				callArgs.push(makeAST(EInteger(100)));
			callArgs.push(message);
		}

		return makeASTWithMeta(ECall(null, "assert_receive", callArgs), n.metadata, n.pos);
	}

	static inline function assertOrRefute(kind:String, expr:ElixirAST, message:Null<ElixirAST>, n:ElixirAST):ElixirAST {
		var args = [expr];
		if (message != null)
			args.push(message);
		return makeASTWithMeta(ECall(null, kind, args), n.metadata, n.pos);
	}

	static function optionIsSomeExpr(value:ElixirAST):ElixirAST {
		return makeAST(ECall(null, "match?", [
			makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("some"))), makeAST(EUnderscore)])),
			value
		]));
	}

	static function optionIsNoneExpr(value:ElixirAST):ElixirAST {
		return makeAST(ECall(null, "match?", [makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("none")))])), value]));
	}

	static function resultIsOkExpr(value:ElixirAST):ElixirAST {
		return makeAST(ECall(null, "match?", [
			makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("ok"))), makeAST(EUnderscore)])),
			value
		]));
	}

	static function resultIsErrorExpr(value:ElixirAST):ElixirAST {
		return makeAST(ECall(null, "match?", [
			makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("error"))), makeAST(EUnderscore)])),
			value
		]));
	}

	static function tryRescueBoolean(fnExpr:ElixirAST, noRaiseValue:Bool, rescueValue:Bool):ElixirAST {
		var callFn = makeAST(ECall(fnExpr, "", []));
		var body = makeAST(EBlock([callFn, makeAST(EBoolean(noRaiseValue))]));
		return makeAST(ETry(body, [
			{
				pattern: EPattern.PWildcard,
				varName: null,
				body: makeAST(EBoolean(rescueValue))
			}
		], [], null, null));
	}

	static inline function isAssertModule(mod:ElixirAST):Bool {
		return switch (mod.def) {
			case EVar("Assert"): true;
			default: false;
		}
	}

	static function isExUnitModule(moduleAst:ElixirAST, body:ElixirAST):Bool {
		if (moduleAst.metadata?.isExunit == true)
			return true;
		return containsUseExUnitCase(body);
	}

	static function containsUseExUnitCase(ast:ElixirAST):Bool {
		var found = false;
		ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			if (!found) {
				switch (n.def) {
					case EUse("ExUnit.Case", _):
						found = true;
					default:
				}
			}
			return n;
		});
		return found;
	}

	static inline function lastArgIndex(args:Array<ElixirAST>):Int {
		return args == null ? -1 : args.length - 1;
	}

	static function takeOptionalNonNilArg(args:Array<ElixirAST>, index:Int):Null<ElixirAST> {
		if (args == null)
			return null;
		if (index < 0 || index >= args.length)
			return null;
		return switch (args[index].def) {
			case ENil: null;
			default: args[index];
		}
	}
}
#end
