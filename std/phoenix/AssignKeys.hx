package phoenix;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * On-demand typed assign keys for LiveSocket typed-key APIs.
 *
 * WHAT
 * - `AssignKeys.of(MyAssigns)` generates a typed key object from your assigns type.
 *
 * WHY
 * - Removes the need to declare a per-module `@:build(...)` key class just to use
 *   `assignKey`/`updateKey`/`assignNewKey`.
 * - Keeps typed-key mode ergonomic while preserving compile-time key and value typing.
 *
 * HOW
 * - The macro reads fields from `MyAssigns`.
 * - Each field becomes a key token of type `AssignKey<MyAssigns, FieldType>`.
 * - Runtime values are Phoenix atom keys (snake_case), matching existing assign lowering.
 *
 * EXAMPLES
 * Haxe:
 *   typedef CounterAssigns = { count:Int, searchQuery:String };
 *   var keys = AssignKeys.of(CounterAssigns);
 *
 *   live = live.assignKey(keys.count, 0);
 *   live = live.assignKey(keys.searchQuery, "term");
 *
 * Elixir:
 *   assign(socket, :count, 0)
 *   assign(socket, :search_query, "term")
 */
class AssignKeys {
	public static macro function of(assignsTypeRef:Expr):Expr {
		var assignsType = phoenix.macros.AssignKeysSupport.resolveAssignsType(assignsTypeRef);
		var assignFields = phoenix.macros.AssignKeysSupport.extractAssignFields(assignsType, assignsTypeRef.pos);
		if (assignFields.length == 0) {
			Context.error("AssignKeys.of(...) requires an assigns type with at least one variable field.", assignsTypeRef.pos);
		}

		var keyObjectFields:Array<ObjectField> = [];
		for (assignField in assignFields) {
			var assignKeyType = phoenix.macros.AssignKeysSupport.buildAssignKeyType(assignsType, assignField.type, assignField.pos);
			var snakeCaseName = phoenix.macros.AssignMacro.camelToSnake(assignField.name);
			var atomExpr:Expr = macro cast(($v{snakeCaseName} : elixir.types.Atom));
			var typedKeyExpr:Expr = {
				expr: ECheckType(atomExpr, assignKeyType),
				pos: assignField.pos
			};
			keyObjectFields.push({
				field: assignField.name,
				expr: typedKeyExpr
			});
		}

		return {
			expr: EObjectDecl(keyObjectFields),
			pos: assignsTypeRef.pos
		};
	}
}
