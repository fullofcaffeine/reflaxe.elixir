package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
 * AnonymousTupleShape defines the representation contract for tuple-shaped
 * Haxe anonymous objects.
 *
 * WHAT
 * - Recognizes canonical contiguous field sets using either `_0.._N-1`
 *   (native Elixir extern convention) or `_1.._N` (portable Haxe convention).
 * - Resolves a typed anonymous field to its zero-based BEAM tuple index.
 *
 * WHY
 * - Object construction already emitted these shapes as Elixir tuples, while
 *   delegated field access and assignment treated them as maps. A value
 *   returned as `{"value", 4}` could therefore be read as `value._1` and fail
 *   at runtime.
 * - One classifier must own construction, reads, and immutable updates so the
 *   representation cannot diverge again.
 *
 * HOW
 * - Parse only canonical `_N` names without leading zeroes.
 * - Sort their numeric ordinals and require a gap-free sequence beginning at
 *   zero or one.
 * - For typed reads/updates, inspect the complete followed anonymous type, not
 *   only the selected field name. Mixed and gapped shapes remain maps.
 *
 * EXAMPLES
 * - `{_1: "ok", _2: 4}` -> `{"ok", 4}`; `value._1` -> `elem(value, 0)`
 * - `{_0: :ok, _1: value}` -> `{:ok, value}`; `result._1` -> `elem(result, 1)`
 * - `{_1: "map", label: "kept"}` remains `%{_1: "map", label: "kept"}`
 *
 * Covered by `regression/tuple_elem_access` and
 * `regression/non_void_tail_values` snapshot/runtime fixtures.
 */
@:nullSafety(Off)
class AnonymousTupleShape {
	static final FIELD_PATTERN = ~/^_(0|[1-9]\d*)$/;

	/** Returns whether the complete field set has a canonical tuple layout. */
	public static function isTupleFieldNames(fieldNames:Array<String>):Bool {
		return layoutFromFieldNames(fieldNames) != null;
	}

	/** Returns the numeric suffix of a canonical `_N` field name. */
	public static function fieldOrdinal(fieldName:String):Null<Int> {
		if (fieldName == null || !FIELD_PATTERN.match(fieldName))
			return null;
		return Std.parseInt(fieldName.substr(1));
	}

	/**
	 * Resolves a tuple-shaped anonymous field to the zero-based BEAM index.
	 * Returns null when the receiver is not a complete canonical tuple shape.
	 */
	public static function fieldIndexForType(receiverType:Null<Type>, fieldName:String):Null<Int> {
		var ordinal = fieldOrdinal(fieldName);
		if (ordinal == null)
			return null;

		var fieldNames = fieldNamesFromType(receiverType, 0);
		var layout = layoutFromFieldNames(fieldNames);
		if (layout == null)
			return null;

		var index = ordinal - layout.base;
		return index >= 0 && index < layout.arity ? index : null;
	}

	static function fieldNamesFromType(type:Null<Type>, depth:Int):Null<Array<String>> {
		if (type == null || depth > 20)
			return null;

		var followed = TypeTools.follow(type);
		return switch (followed) {
			case TAnonymous(anonymousRef):
				[for (field in anonymousRef.get().fields) field.name];
			case TAbstract(abstractRef, params):
				var abstractType = abstractRef.get();
				if (abstractType.name == "Null" && params != null && params.length == 1) {
					fieldNamesFromType(params[0], depth + 1);
				} else {
					null;
				}
			case TMono(monoRef):
				var resolved = monoRef.get();
				resolved == null ? null : fieldNamesFromType(resolved, depth + 1);
			case TLazy(loader):
				fieldNamesFromType(loader(), depth + 1);
			case TType(typeRef, _):
				fieldNamesFromType(typeRef.get().type, depth + 1);
			default:
				null;
		}
	}

	static function layoutFromFieldNames(fieldNames:Null<Array<String>>):Null<{base:Int, arity:Int}> {
		if (fieldNames == null || fieldNames.length == 0)
			return null;

		var ordinals:Array<Int> = [];
		for (fieldName in fieldNames) {
			var ordinal = fieldOrdinal(fieldName);
			if (ordinal == null)
				return null;
			ordinals.push(ordinal);
		}
		ordinals.sort((left, right) -> left - right);

		var base = ordinals[0];
		if (base != 0 && base != 1)
			return null;

		for (index in 0...ordinals.length) {
			if (ordinals[index] != base + index)
				return null;
		}

		return {base: base, arity: ordinals.length};
	}
}
#end
