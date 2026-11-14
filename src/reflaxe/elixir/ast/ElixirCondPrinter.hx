package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;

/** Recursive expression and indentation services owned by the main printer. */
typedef CondPrintInput = {
	final clauses:Array<ECondClause>;
	final indent:Int;
	final print:(ElixirAST, Int) -> String;
	final indentStr:Int->String;
	final indentBody:(String, Int) -> String;
}

/**
 * WHAT: Prints cond clauses without changing their expressions or effects.
 * WHY: Elixir requires a body after every arrow, even when Haxe's branch is
 * empty. Printing `condition ->` alone is invalid; `condition -> nil` is valid.
 * Elixir also requires one expression before the arrow. A method call on a new
 * object, such as `~/^[0-9]+$/.match(text)` in a switch guard, arrives here as
 * two statements: store the object, then call the method.
 * HOW: Reuse the main printer's expression and indentation services. Preserve
 * existing single-line and multiline formatting, with nil for an empty body.
 * Print a test of several statements as `(fn -> ... end).()`, so it stays one
 * expression, runs once, and runs only when the clause is reached.
 * EXAMPLE: A nullable statement switch can have a no-op null branch before
 * matching its enum constructor. The nullable_enum_cond fixture checks that
 * this branch still permits the following statement to execute. The
 * method_call_receiver_in_cond_condition fixture checks the several-statement test.
 */
function printCond(input:CondPrintInput):String {
	final clauses:Array<String> = [];
	for (clause in input.clauses) {
		final condition = switch clause.condition.def {
			case EBlock(expressions) if (expressions.length > 1):
				// The test of a clause must be one expression. Wrap a block of several
				// statements in a function that is called at once, as the printer does
				// for a block used as a function argument or as an operand.
				'(fn ->\n${input.indentBody(input.print(clause.condition, 0), input.indent + 2)}\n${input.indentStr(input.indent + 1)}end).()';
			case _:
				input.print(clause.condition, 0);
		};
		var body = input.print(clause.body, 0);
		if (StringTools.trim(body) == "")
			body = "nil";

		final multiline = switch clause.body.def {
			case EIf(_, _, _) | ECase(_, _) | ECond(_) | EWith(_, _, _): true;
			case EBlock(expressions) if (expressions.length > 1): true;
			case _: body.indexOf("\n") >= 0;
		};
		final prefix = input.indentStr(input.indent + 1);
		clauses.push(multiline ? '${prefix}${condition} ->\n${input.indentBody(body, input.indent + 2)}' : '${prefix}${condition} -> ${body}');
	}

	return 'cond do\n${clauses.join("\n")}\n${input.indentStr(input.indent)}end';
}
#end
