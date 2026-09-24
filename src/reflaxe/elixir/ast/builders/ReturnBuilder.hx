package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.CompilationContext;

/**
 * Builds the complete value of a Haxe return using the existing expression builders.
 *
 * Elixir returns the final expression. Haxe can lower a returned switch into a
 * block that first saves fields or effects in locals. Keep that entire block:
 * the switch branches can still read those locals, including the saved receiver.
 * Return/control-flow metadata remains owned by ElixirASTBuilder; this builder
 * must not extract a final switch or substitute its receiver independently.
 */
@:nullSafety(Off)
class ReturnBuilder {
	/** Preserve evaluation order and bindings while lowering the returned value. */
	public static function build(e:Null<TypedExpr>, context:CompilationContext):Null<ElixirASTDef> {
		if (e == null)
			return ENil;
		if (context.compiler == null)
			return null;
		var result = ElixirASTBuilder.buildFromTypedExpr(e, context);
		return result == null ? null : result.def;
	}
}
#end
