package phoenix.macros;

#if macro
import haxe.macro.Expr;
#end

/**
 * Macro helpers for typed Phoenix LiveView stream operations.
 *
 * WHAT
 * - Lowers typed stream-name helper calls to Phoenix.LiveView stream functions.
 *
 * WHY
 * - The public Haxe API should keep Phoenix's primitives visible while pairing
 *   stream names with item types at compile time.
 *
 * HOW
 * - Field-shaped token expressions such as `streams.todos` emit a direct atom
 *   (`:todos`) for handwritten-looking Elixir.
 * - Computed token expressions pass through as normal atom-backed values.
 */
#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class LiveStreamMacro {
	#if macro
	public static function processStream(socketExpr:Expr, streamNameExpr:Expr, itemsExpr:Expr, ?optsExpr:Expr):Expr {
		var nameExpr = normalizeStreamName(streamNameExpr);
		return if (isMissingOptional(optsExpr)) {
			macro phoenix.Phoenix.LiveView.stream($socketExpr, $e{nameExpr}, $itemsExpr);
		} else {
			macro phoenix.Phoenix.LiveView.stream($socketExpr, $e{nameExpr}, $itemsExpr, $optsExpr);
		}
	}

	public static function processStreamInsert(socketExpr:Expr, streamNameExpr:Expr, itemExpr:Expr, ?optsExpr:Expr):Expr {
		var nameExpr = normalizeStreamName(streamNameExpr);
		return if (isMissingOptional(optsExpr)) {
			macro phoenix.Phoenix.LiveView.streamInsert($socketExpr, $e{nameExpr}, $itemExpr);
		} else {
			macro phoenix.Phoenix.LiveView.streamInsert($socketExpr, $e{nameExpr}, $itemExpr, $optsExpr);
		}
	}

	public static function processStreamDelete(socketExpr:Expr, streamNameExpr:Expr, itemExpr:Expr, ?optsExpr:Expr):Expr {
		var nameExpr = normalizeStreamName(streamNameExpr);
		return if (isMissingOptional(optsExpr)) {
			macro phoenix.Phoenix.LiveView.streamDelete($socketExpr, $e{nameExpr}, $itemExpr);
		} else {
			macro phoenix.Phoenix.LiveView.streamDelete($socketExpr, $e{nameExpr}, $itemExpr, $optsExpr);
		}
	}

	private static function isMissingOptional(expr:Null<Expr>):Bool {
		if (expr == null) {
			return true;
		}
		return switch (expr.expr) {
			case EConst(CIdent("null")):
				true;
			case _:
				false;
		};
	}

	private static function normalizeStreamName(streamNameExpr:Expr):Expr {
		var fieldName = extractTypedStreamFieldName(streamNameExpr);
		if (fieldName == null) {
			return streamNameExpr;
		}

		var atomKeyExpr:Expr = macro(($v{phoenix.macros.AssignMacro.camelToSnake(fieldName)} : elixir.types.Atom));
		return atomKeyExpr;
	}

	private static function extractTypedStreamFieldName(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EField(_, field):
				field;
			case EParenthesis(inner):
				extractTypedStreamFieldName(inner);
			case ECheckType(inner, _):
				extractTypedStreamFieldName(inner);
			case EMeta(_, inner):
				extractTypedStreamFieldName(inner);
			case _:
				null;
		};
	}
	#end
}
