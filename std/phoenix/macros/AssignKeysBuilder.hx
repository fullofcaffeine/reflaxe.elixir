package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class AssignKeysBuilder {
	#if macro
	/**
	 * Build macro for generating typed assign-key constants.
	 *
	 * WHAT
	 * - Generates `public static inline var <field>:AssignKey<TAssigns, TField>` entries.
	 *
	 * WHY
	 * - The generated constants are regular typed fields, so IDE completion (`--display`) can
	 *   suggest keys and the typer can enforce key-specific value types in `LiveSocket.assign`.
	 *
	 * HOW
	 * - Resolves the assigns type from either an expression (`CounterAssigns`) or a string
	 *   (`"my.pkg.CounterAssigns"`) using `Context.getType`.
	 * - Enumerates fields on the resolved type and emits typed constants where each runtime value
	 *   is a Phoenix atom key (`:snake_case_field`).
	 *
	 * EXAMPLES
	 * Haxe:
	 *   @:build(phoenix.macros.AssignKeysBuilder.build(CounterAssigns))
	 *   class CounterAssignKeys {}
	 *
	 *   socket.assignKey(CounterAssignKeys.count, 0);
	 *
	 * Elixir:
	 *   assign(socket, :count, 0)
	 */
	public static macro function build(assignsTypeRef:Expr):Array<Field> {
		var buildFields = Context.getBuildFields();
		var assignsType = AssignKeysSupport.resolveAssignsType(assignsTypeRef);
		var assignFields = AssignKeysSupport.extractAssignFields(assignsType, assignsTypeRef.pos);

		if (assignFields.length == 0) {
			Context.error("Assign key generation requires an assigns type with at least one variable field.", assignsTypeRef.pos);
		}

		for (assignField in assignFields) {
			var assignKeyType = AssignKeysSupport.buildAssignKeyType(assignsType, assignField.type, assignField.pos);

			var snakeCaseName = AssignMacro.camelToSnake(assignField.name);
			var valueExpr = macro cast(($v{snakeCaseName} : elixir.types.Atom));

			buildFields.push({
				name: assignField.name,
				access: [APublic, AStatic, AInline],
				kind: FVar(assignKeyType, valueExpr),
				pos: assignField.pos,
				doc: 'Generated assign key for "${assignField.name}" (emits :${snakeCaseName}).'
			});
		}

		return buildFields;
	}
	#end
}
