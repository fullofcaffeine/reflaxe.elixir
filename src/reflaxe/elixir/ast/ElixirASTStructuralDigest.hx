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

	/**
	 * Returns true when two trees are the same for every later reader.
	 *
	 * WHAT
	 * - Compares `def` payloads deeply, like `digest`, and also compares each node's
	 *   metadata and source position, which `digest` leaves out.
	 * - Metadata matches when it is the same object or when every field holds the
	 *   same value or object. A copied record with the same values matches; a record
	 *   with one changed field does not.
	 *
	 * WHY
	 * - `-D reflaxe_elixir_verify_pass_preconditions` runs each skipped pass anyway
	 *   and must prove that the skip lost nothing. A pass that only changes metadata
	 *   still changes what later passes and the printer read, so a digest of `def`
	 *   values alone is not enough.
	 *
	 * HOW
	 * - Identical objects match at once, so an unchanged subtree costs nothing.
	 * - Class and function payloads match only when they are the same object. This
	 *   can report a difference that does not matter, never the reverse.
	 *
	 * EXAMPLE
	 * - A pass that returns `makeASTWithMeta(n.def, n.metadata, n.pos)` for every node
	 *   is equivalent to its input. A pass that sets `metadata.isLiveView` on one
	 *   node is not, even though its digest is unchanged.
	 */
	public static function equivalent(left:ElixirAST, right:ElixirAST):Bool {
		if (left == right)
			return true;
		if (left == null || right == null)
			return false;
		return sameMetadata(left.metadata, right.metadata) && samePosition(left.pos, right.pos) && equalValues(left.def, right.def);
	}

	// BOUNDARY_DYNAMIC: diagnostic comparison of enum payloads and records, the same
	// reflective boundary as `appendValue`; used only by the verification mode.
	static function equalValues(left:Dynamic, right:Dynamic):Bool {
		if (left == right)
			return true;
		if (left == null || right == null)
			return false;
		if (Std.isOfType(left, String) || Std.isOfType(right, String))
			return false;
		if (Std.isOfType(left, Array)) {
			if (!Std.isOfType(right, Array))
				return false;
			var leftValues:Array<Dynamic> = cast left;
			var rightValues:Array<Dynamic> = cast right;
			if (leftValues.length != rightValues.length)
				return false;
			for (index in 0...leftValues.length)
				if (!equalValues(leftValues[index], rightValues[index]))
					return false;
			return true;
		}
		return switch (Type.typeof(left)) {
			case TEnum(enumType):
				switch (Type.typeof(right)) {
					case TEnum(otherType) if (otherType == enumType && Type.enumIndex(left) == Type.enumIndex(right)):
						var leftParameters = Type.enumParameters(left);
						var rightParameters = Type.enumParameters(right);
						var same = leftParameters.length == rightParameters.length;
						var index = 0;
						while (same && index < leftParameters.length) {
							same = equalValues(leftParameters[index], rightParameters[index]);
							index++;
						}
						same;
					default:
						false;
				}
			case TObject:
				if (Reflect.hasField(left,
					"def") && Reflect.hasField(left,
						"metadata") && Reflect.hasField(left,
						"pos")) Reflect.hasField(right, "def") && equivalent(cast left, cast right); else sameFields(left, right, true);
			default:
				false;
		};
	}

	// BOUNDARY_DYNAMIC: metadata is a wide optional record; compare its fields by value or identity.
	static function sameMetadata(left:Dynamic, right:Dynamic):Bool {
		if (left == right)
			return true;
		if (left == null || right == null)
			return false;
		return sameFields(left, right, false);
	}

	// BOUNDARY_DYNAMIC: anonymous records (clauses, attributes, metadata) compared field by field.
	static function sameFields(left:Dynamic, right:Dynamic, deep:Bool):Bool {
		var leftFields = Reflect.fields(left);
		var rightFields = Reflect.fields(right);
		var present = new Map<String, Bool>();
		for (field in leftFields)
			if (Reflect.field(left, field) != null)
				present.set(field, true);
		for (field in rightFields)
			if (Reflect.field(right, field) != null && !present.exists(field))
				return false;
		for (field in present.keys()) {
			var leftValue = Reflect.field(left, field);
			var rightValue = Reflect.field(right, field);
			if (deep ? !equalValues(leftValue, rightValue) : leftValue != rightValue)
				return false;
		}
		return true;
	}

	static function samePosition(left:Null<haxe.macro.Expr.Position>, right:Null<haxe.macro.Expr.Position>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null)
			return false;
		return Std.string(left) == Std.string(right);
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
