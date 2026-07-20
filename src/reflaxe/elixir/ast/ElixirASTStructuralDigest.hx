package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
/**
 * Deterministic fingerprint of structural `ElixirAST` content.
 *
 * WHAT
 * - Hashes constructors, scalar payloads, patterns, records, and child AST in
 *   deterministic field order without invoking the Elixir printer.
 *
 * WHY
 * - Intermediate trees may intentionally contain compiler-only nodes such as
 *   `EReceiverEffect`, which the printer must reject. Debug change detection
 *   still needs to compare those trees safely.
 *
 * HOW
 * - Recursively encodes only each node's structural `def` value.
 * - Source positions and the broad legacy metadata record are deliberately not
 *   included. Correct invalidation comes from `PassOutcome`; this digest is a
 *   diagnostic for structural change, not a preservation proof.
 */
class ElixirASTStructuralDigest {
	public static function digest(ast:ElixirAST):String {
		var digest = new StructuralDigestState();
		appendAst(digest, ast);
		return digest.finish();
	}

	static function appendAst(digest:StructuralDigestState, ast:ElixirAST):Void {
		if (ast == null) {
			digest.add("ast", "null");
			return;
		}
		digest.add("ast", "begin");
		appendValue(digest, ast.def);
		digest.add("ast", "end");
	}

	static function appendValue(digest:StructuralDigestState, value:Dynamic):Void {
		if (value == null) {
			digest.add("null", "");
			return;
		}
		if (Std.isOfType(value, String)) {
			digest.add("string", cast value);
			return;
		}
		if (Std.isOfType(value, Array)) {
			var values:Array<Dynamic> = cast value;
			digest.add("array", Std.string(values.length));
			for (item in values)
				appendValue(digest, item);
			return;
		}

		switch (Type.typeof(value)) {
			case TNull:
				digest.add("null", "");
			case TInt:
				digest.add("int", Std.string(value));
			case TFloat:
				digest.add("float", Std.string(value));
			case TBool:
				digest.add("bool", Std.string(value));
			case TEnum(enumType):
				digest.add("enum", Type.getEnumName(enumType));
				digest.add("constructor", Type.enumConstructor(value));
				for (parameter in Type.enumParameters(value))
					appendValue(digest, parameter);
			case TObject:
				if (Reflect.hasField(value, "def") && Reflect.hasField(value, "metadata") && Reflect.hasField(value, "pos")) {
					appendAst(digest, cast value);
				} else {
					var fields = Reflect.fields(value);
					fields.sort(Reflect.compare);
					digest.add("object", Std.string(fields.length));
					for (field in fields) {
						digest.add("field", field);
						appendValue(digest, Reflect.field(value, field));
					}
				}
			case TClass(classType):
				throw 'Structural digest does not support class payload ${Type.getClassName(classType)}';
			case TFunction:
				throw "Structural digest does not support function payloads";
			case TUnknown:
				throw "Structural digest encountered an unknown payload";
		}
	}
}

/** Allocation-bounded streaming state for the diagnostic structural fingerprint. */
private class StructuralDigestState {
	var left:Int = 0x13579bdf;
	var right:Int = 0x2468ace0;
	var characterCount:Int = 0;

	public function new() {}

	public function add(kind:String, value:String):Void {
		var safeValue = value == null ? "" : value;
		addString(kind);
		addCode(31);
		addString(Std.string(safeValue.length));
		addCode(30);
		addString(safeValue);
		addCode(29);
	}

	public function finish():String {
		return StringTools.hex(left, 8) + StringTools.hex(right, 8) + StringTools.hex(characterCount, 8);
	}

	function addString(value:String):Void {
		for (index in 0...value.length)
			addCode(value.charCodeAt(index));
	}

	function addCode(code:Int):Void {
		left = left * 31 + code;
		right = ((right << 5) - right) ^ code;
		characterCount++;
	}
}
#end
