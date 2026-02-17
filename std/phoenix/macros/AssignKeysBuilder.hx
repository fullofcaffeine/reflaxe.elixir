package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
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
		var assignsType = resolveAssignsType(assignsTypeRef);
		var assignsComplexType = requireComplexType(assignsType, assignsTypeRef.pos, "assigns type");
		var assignFields = extractAssignFields(assignsType, assignsTypeRef.pos);

		if (assignFields.length == 0) {
			Context.error("Assign key generation requires an assigns type with at least one variable field.", assignsTypeRef.pos);
		}

		for (assignField in assignFields) {
			var fieldTypeComplex = requireComplexType(assignField.type, assignField.pos, 'field "${assignField.name}"');
			var assignKeyType:ComplexType = TPath({
				pack: ["phoenix", "types"],
				name: "AssignKey",
				params: [TPType(assignsComplexType), TPType(fieldTypeComplex)]
			});

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

	private static function resolveAssignsType(assignsTypeRef:Expr):Type {
		var typeName = switch (assignsTypeRef.expr) {
			case EConst(CString(name, _)): name;
			case _: expressionToTypeName(assignsTypeRef);
		};

		var candidateNames:Array<String> = [typeName];
		if (typeName.indexOf(".") == -1) {
			var localClass = Context.getLocalClass();
			if (localClass != null) {
				var classData = localClass.get();
				var moduleName = classData.module;
				candidateNames.push(moduleName + "." + typeName);
				if (classData.pack.length > 0) {
					candidateNames.push(classData.pack.join(".") + "." + typeName);
				}
			}
		}

		for (candidateName in candidateNames) {
			var resolvedType = tryResolveType(candidateName);
			if (resolvedType != null) {
				return resolvedType;
			}
		}

		Context.error('Unable to resolve assigns type "$typeName" for assign key generation.', assignsTypeRef.pos);
		return null;
	}

	private static function tryResolveType(typeName:String):Null<Type> {
		return try {
			Context.getType(typeName);
		} catch (_:Any) {
			null;
		};
	}

	private static function expressionToTypeName(expr:Expr):String {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name;
			case EField(owner, field):
				expressionToTypeName(owner) + "." + field;
			case EParenthesis(inner):
				expressionToTypeName(inner);
			case _:
				Context.error("Expected assigns type reference (e.g. CounterAssigns or \"pkg.CounterAssigns\").", expr.pos);
				null;
		};
	}

	private static function requireComplexType(type:Type, pos:Position, context:String):ComplexType {
		var complexType = type.toComplexType();
		if (complexType == null) {
			Context.error('Unable to represent $context as a ComplexType for generated assign keys.', pos);
		}
		return complexType;
	}

	private static function extractAssignFields(type:Type, pos:Position):Array<{name:String, type:Type, pos:Position}> {
		return switch (type.follow()) {
			case TAnonymous(ref):
				var anon = ref.get();
				[
					for (field in anon.fields)
						switch (field.kind) {
							case FVar(_, _):
								{name: field.name, type: field.type, pos: field.pos};
							case _:
								null;
						}
				].filter((item) -> item != null);
			case TType(ref, params):
				extractAssignFields(ref.get().type.applyTypeParameters(ref.get().params, params), pos);
			case TInst(ref, _):
				var classType = ref.get();
				[
					for (field in classType.fields.get())
						switch (field.kind) {
							case FVar(_, _):
								{name: field.name, type: field.type, pos: field.pos};
							case _:
								null;
						}
				].filter((item) -> item != null);
			case _:
				Context.error("Assign keys can only be generated from a typedef/object/class assigns type.", pos);
				[];
		};
	}
	#end
}
