package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
#end

/**
 * Shared helpers for typed assign-key generation.
 *
 * WHAT
 * - Provides common macro utilities used by:
 *   - `AssignKeysBuilder` (`@:build` class constants)
 *   - `phoenix.AssignKeys.of(...)` (inline key-object generation)
 *
 * WHY
 * - Keeps key generation behavior consistent across both APIs:
 *   same assigns-type resolution rules, same field extraction rules, same typing.
 */
#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class AssignKeysSupport {
	#if macro
	public static function resolveAssignsType(assignsTypeRef:Expr):Type {
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

	public static function requireComplexType(type:Type, pos:Position, context:String):ComplexType {
		var complexType = type.toComplexType();
		if (complexType == null) {
			Context.error('Unable to represent $context as a ComplexType for generated assign keys.', pos);
		}
		return complexType;
	}

	public static function extractAssignFields(type:Type, pos:Position):Array<{name:String, type:Type, pos:Position}> {
		return switch (type.follow()) {
			case TAnonymous(ref):
				[
					for (field in ref.get().fields)
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
				[
					for (field in ref.get().fields.get())
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

	public static function buildAssignKeyType(assignsType:Type, fieldType:Type, fieldPos:Position):ComplexType {
		var assignsComplexType = requireComplexType(assignsType, fieldPos, "assigns type");
		var fieldComplexType = requireComplexType(fieldType, fieldPos, "assign field");
		return TPath({
			pack: ["phoenix", "types"],
			name: "AssignKey",
			params: [TPType(assignsComplexType), TPType(fieldComplexType)]
		});
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
	#end
}
