package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTPrinter;

/** Literal data remains data in binaries, quoted atoms, and keyword keys. */
class TestElixirLiteralPrinting {
	public static function run():Expr {
		check(EStringLiteral('quote " slash \\ #{literal}'), '"quote \\" slash \\\\ \\#{literal}"');
		check(EAtom('scope-tag'), ':"scope-tag"');
		check(EAtom('quote"#{literal}'), ':"quote\\"\\#{literal}"');
		check(EKeywordList([{key: "scope-tag", value: makeAST(EAtom("scope_id"))}]), '["scope-tag": :scope_id]');
		Sys.println("Elixir literal printing contracts passed");
		return macro null;
	}

	static function check(node:ElixirASTDef, expected:String):Void {
		var actual = ElixirASTPrinter.print(makeAST(node), 0);
		if (actual != expected)
			Context.fatalError('Expected ' + expected + ' but got ' + actual, Context.currentPos());
	}
}
#end
