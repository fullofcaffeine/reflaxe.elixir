package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
 * TypeUtils
 *
 * WHAT
 * - Small helpers for reasoning about Haxe macro `Type` values in the Elixir AST pipeline.
 *
 * WHY
 * - Some compile-time marker abstracts (notably `elixir.types.Atom`) affect how literals must be
 *   printed in Elixir, but Haxe often represents those values as *other* abstracts layered over
 *   `Atom` (e.g. enum abstracts like `TimeUnit(Atom)`).
 * - If we only detect `elixir.types.Atom` directly, enum-abstract atoms are emitted as strings
 *   (e.g. `"second"`) which breaks Elixir APIs expecting atoms (e.g. `DateTime.truncate/2` wants
 *   `:second`).
 *
 * HOW
 * - Follow typedefs/monos and walk abstract-underlying-type chains until we either find
 *   `elixir.types.Atom` or hit a non-abstract terminal type.
 *
 * EXAMPLES
 * - Haxe:
 *     enum abstract TimePrecision(elixir.types.Atom) from elixir.types.Atom {
 *       var Second = "second";
 *     }
 *   Elixir:
 *     DateTime.truncate(dt, :second)
 */
@:nullSafety(Off)
class TypeUtils {
	public static function isStringType(t:Null<Type>):Bool {
		var followed = followNullable(t);
		return switch (followed) {
			case TInst(_.get() => {name: "String"}, _): true;
			case TAbstract(_.get() => {name: "String"}, _): true;
			default: false;
		}
	}

	public static function isIntType(t:Null<Type>):Bool {
		var followed = followNullable(t);
		return switch (followed) {
			case TAbstract(_.get() => {name: "Int"}, _): true;
			default: false;
		}
	}

	public static function isFloatType(t:Null<Type>):Bool {
		var followed = followNullable(t);
		return switch (followed) {
			case TAbstract(_.get() => {name: "Float"}, _): true;
			default: false;
		}
	}

	/**
	 * Returns true for Haxe values represented as plain Elixir lists.
	 *
	 * Some stdlib types are abstracts over `Array<T>`. For example, `haxe.CallStack`
	 * behaves like an array but may still appear to the backend as the abstract type.
	 * Elixir lists do not have a `.length` field, so these values must use
	 * `length(value)` instead.
	 */
	public static function isListBackedType(t:Null<Type>):Bool {
		return isListBackedTypeInner(t, 0);
	}

	/**
	 * Returns true when a value may carry Haxe Float special values.
	 *
	 * This is deliberately conservative for Dynamic, unresolved monos, and type
	 * parameters because `Math.NaN` can be hidden behind those types. Concrete Int
	 * expressions still keep native Elixir arithmetic on the fast path.
	 */
	public static function mayContainHaxeFloat(t:Null<Type>):Bool {
		return mayContainHaxeFloatInner(t, 0);
	}

	public static function isElixirAtomType(t:Null<Type>):Bool {
		return isElixirAtomTypeInner(t, 0);
	}

	/**
	 * Returns true for the explicit `elixir.types.Term` native BEAM boundary.
	 *
	 * Unlike ordinary `Dynamic`, `Term` deliberately asks the target to preserve
	 * native BEAM term behavior. Detect it before following the abstract to its
	 * `Dynamic` carrier so operator builders can honor that declared boundary.
	 */
	public static function isElixirTermType(t:Null<Type>):Bool {
		return isElixirTermTypeInner(t, 0);
	}

	public static function mayBeNil(t:Null<Type>):Bool {
		return mayBeNilInner(t, 0);
	}

	static function followNullable(t:Null<Type>):Null<Type> {
		if (t == null)
			return null;
		return TypeTools.follow(t);
	}

	static function mayContainHaxeFloatInner(t:Null<Type>, depth:Int):Bool {
		if (t == null)
			return true;
		if (depth > 20)
			return true;

		var followed = TypeTools.follow(t);
		return switch (followed) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				if (abstractType.name == "Float") {
					true;
				} else if (abstractType.name == "Int" || abstractType.name == "Bool" || abstractType.name == "String") {
					false;
				} else if (abstractType.name == "Null" && params != null && params.length == 1) {
					mayContainHaxeFloatInner(params[0], depth + 1);
				} else {
					mayContainHaxeFloatInner(abstractType.type, depth + 1);
				}
			case TDynamic(_):
				true;
			case TMono(monoRef): var resolved = monoRef.get(); resolved == null || mayContainHaxeFloatInner(resolved, depth + 1);
			case TLazy(thunk):
				mayContainHaxeFloatInner(thunk(), depth + 1);
			case TType(typeRef, params):
				var typeDefinition = typeRef.get();
				if (params != null && params.length > 0) {
					for (param in params) {
						if (mayContainHaxeFloatInner(param, depth + 1))
							return true;
					}
				}
				mayContainHaxeFloatInner(typeDefinition.type, depth + 1);
			case TFun(args, result):
				mayContainHaxeFloatInner(result, depth + 1);
			default:
				false;
		}
	}

	static function isListBackedTypeInner(t:Null<Type>, depth:Int):Bool {
		if (t == null)
			return false;
		if (depth > 20)
			return false;

		var followed = TypeTools.follow(t);
		if (matchesListBackedType(followed))
			return true;

		return switch (followed) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				if (abstractType.name == "Null" && params != null && params.length == 1) {
					isListBackedTypeInner(params[0], depth + 1);
				} else {
					isListBackedTypeInner(abstractType.type, depth + 1);
				}
			case TType(typeRef, _):
				isListBackedTypeInner(typeRef.get().type, depth + 1);
			case TLazy(thunk):
				isListBackedTypeInner(thunk(), depth + 1);
			case TMono(monoRef): var resolved = monoRef.get(); resolved != null && isListBackedTypeInner(resolved, depth + 1);
			default:
				false;
		}
	}

	static function matchesListBackedType(t:Null<Type>):Bool {
		return switch (t) {
			case TInst(ref, _): var classType = ref.get(); classType.pack.length == 0 && classType.name == "Array";
			case TAbstract(ref, _): var abstractType = ref.get(); abstractType.pack.length == 0 && (abstractType.name == "Array"
					|| abstractType.name == "NativeArray");
			default:
				false;
		};
	}

	static function isElixirAtomTypeInner(t:Null<Type>, depth:Int):Bool {
		if (t == null)
			return false;
		if (depth > 20)
			return false;

		var followed = TypeTools.follow(t);

		return switch (followed) {
			case TAbstract(ref, _):
				var at = ref.get();
				if (at.pack.join(".") == "elixir.types" && at.name == "Atom") {
					true;
				} else {
					isElixirAtomTypeInner(at.type, depth + 1);
				}
			case TType(td, _):
				isElixirAtomTypeInner(td.get().type, depth + 1);
			case TLazy(f):
				isElixirAtomTypeInner(f(), depth + 1);
			default:
				false;
		}
	}

	static function isElixirTermTypeInner(t:Null<Type>, depth:Int):Bool {
		if (t == null || depth > 20)
			return false;

		return switch (t) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Term") {
					true;
				} else if (abstractType.name == "Null" && params != null && params.length == 1) {
					isElixirTermTypeInner(params[0], depth + 1);
				} else {
					isElixirTermTypeInner(abstractType.type, depth + 1);
				}
			case TType(typeRef, _):
				isElixirTermTypeInner(typeRef.get().type, depth + 1);
			case TLazy(thunk):
				isElixirTermTypeInner(thunk(), depth + 1);
			case TMono(monoRef): var resolved = monoRef.get(); resolved != null && isElixirTermTypeInner(resolved, depth + 1);
			default:
				false;
		}
	}

	static function mayBeNilInner(t:Null<Type>, depth:Int):Bool {
		if (t == null)
			return true;
		if (depth > 20)
			return true;

		var followed = TypeTools.follow(t);
		return switch (followed) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				if (abstractType.name == "Null" && params != null && params.length == 1) {
					true;
				} else if (abstractType.name == "Int" || abstractType.name == "Float" || abstractType.name == "Bool" || abstractType.name == "String") {
					false;
				} else {
					mayBeNilInner(abstractType.type, depth + 1);
				}
			case TDynamic(_):
				true;
			case TMono(monoRef): var resolved = monoRef.get(); resolved == null || mayBeNilInner(resolved, depth + 1);
			case TLazy(thunk):
				mayBeNilInner(thunk(), depth + 1);
			case TType(typeRef, _):
				mayBeNilInner(typeRef.get().type, depth + 1);
			default:
				false;
		}
	}
}
#end
