package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.transformers.EctoMigrationExsTransforms;

/** Checks builder data flow independently of generated migration snapshots. */
@:access(reflaxe.elixir.ast.transformers.EctoMigrationExsTransforms)
class TestMigrationChainTransforms {
	static function call(name:String, receiver:ElixirAST):ElixirAST {
		return makeAST(ECall(null, name, [receiver]));
	}

	static function bind(name:String, value:ElixirAST):ElixirAST {
		return makeAST(EMatch(PVar(name), value));
	}

	static function variable(name:String):ElixirAST
		return makeAST(EVar(name));

	public static function run():Expr {
		final create = call("create_table", variable("struct"));
		final add = call("add_column", variable("first"));
		final block = makeAST(EBlock([bind("first", create), add]));
		final expanded = EctoMigrationExsTransforms.flattenTopLevelStatements([bind("second", block)]);
		if (expanded.length != 2)
			fail("block assignment must retain two calls");
		switch (expanded[0].def) {
			case EMatch(PVar("first"), value) if (value == create):
			default:
				fail("prefix binding must keep its original owner");
		}
		switch (expanded[1].def) {
			case EMatch(PVar("second"), value) if (value == add):
			default:
				fail("outer binding must receive the last expression, not the first");
		}

		final wrapper = makeAST(ECall(makeAST(EFn([{args: [], guard: null, body: block}])), "", []));
		final wrapped = EctoMigrationExsTransforms.extractCallChain(wrapper);
		if (wrapped == null || wrapped.calls.map(c -> c.name).join(",") != "create_table,add_column")
			fail("immediately invoked builder block must retain its complete chain");

		final statements = [
			             bind("second", wrapper), bind("third", call("add_index", variable("second"))),
			call("add_index", variable("third")),             call("add_index", variable("unrelated"))
		];
		final sequential = EctoMigrationExsTransforms.extractSequentialCallChain(statements, 0);
		if (sequential == null
			|| sequential.nextIndex != 3
			|| sequential.chain.calls.map(c -> c.name).join(",") != "create_table,add_column,add_index,add_index")
			fail("fresh receiver names must follow returned values and stop at an unrelated receiver");

		final extraEffect = makeAST(EBlock([bind("first", create), call("observe", variable("first")), add]));
		if (EctoMigrationExsTransforms.extractCallChain(extraEffect) != null)
			fail("builder extraction must not silently discard an unrelated effect");
		final wrongReceiver = makeAST(EBlock([bind("first", create), call("add_column", variable("other"))]));
		if (EctoMigrationExsTransforms.extractCallChain(wrongReceiver) != null)
			fail("builder extraction must not substitute a different receiver");
		Sys.println("Migration chain transform contracts passed");
		return macro null;
	}

	static function fail(message:String):Void
		Context.fatalError(message, Context.currentPos());
}
#end
