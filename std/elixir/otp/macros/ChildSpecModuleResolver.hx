package elixir.otp.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.builders.ModuleBuilder;

using haxe.macro.Tools;
#end

/**
 * Shared macro helper for resolving typed child-spec module refs.
 *
 * WHY
 * - Centralizes strict compile-time checks for `TypeSafeChildSpec` typed APIs.
 * - Keeps error messages consistent across endpoint/repo/pubsub/worker helpers.
 */
class ChildSpecModuleResolver {
	#if macro
	static function unwrap(expr:Expr):Expr {
		return switch (expr.expr) {
			case EParenthesis(inner):
				unwrap(inner);
			case ECheckType(inner, _):
				unwrap(inner);
			case EMeta(_, inner):
				unwrap(inner);
			case ECast(inner, _):
				unwrap(inner);
			default:
				expr;
		};
	}

	static function extractDotPath(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CIdent(ident)):
				ident;
			case EField(owner, field):
				var ownerPath = extractDotPath(owner);
				ownerPath != null ? ownerPath + "." + field : null;
			default:
				null;
		};
	}

	static function moduleNameFromModuleType(moduleType:ModuleType):Null<String> {
		return switch (moduleType) {
			case TClassDecl(classRef):
				ModuleBuilder.extractModuleName(classRef.get());
			case TTypeDecl(typeRef):
				moduleNameFromType(typeRef.get().type);
			case TAbstract(abstractRef):
				var abstractType = abstractRef.get();
				abstractType.pack.length > 0 ? abstractType.pack.join(".") + "." + abstractType.name : abstractType.name;
			case TEnumDecl(enumRef):
				var enumType = enumRef.get();
				enumType.pack.length > 0 ? enumType.pack.join(".") + "." + enumType.name : enumType.name;
		};
	}

	static function moduleNameFromType(type:Type):Null<String> {
		return switch (type.follow()) {
			case TInst(classRef, params):
				var classType = classRef.get();
				if (classType.name == "Class" && params != null && params.length == 1) {
					moduleNameFromType(params[0]);
				} else {
					ModuleBuilder.extractModuleName(classType);
				}
			case TType(typeRef, params):
				var typeDef = typeRef.get();
				if (typeDef.name == "Class" && params != null && params.length == 1) {
					moduleNameFromType(params[0]);
				} else {
					moduleNameFromType(typeDef.type);
				}
			case TMono(monoRef):
				var resolvedMono = monoRef.get();
				resolvedMono != null ? moduleNameFromType(resolvedMono) : null;
			case TLazy(loader):
				moduleNameFromType(loader());
			default:
				null;
		};
	}

	public static function resolveModuleName(moduleRef:Expr, typedApiName:String, unsafeApiName:String):String {
		var normalizedExpr = unwrap(moduleRef);
		switch (normalizedExpr.expr) {
			case EConst(CString(moduleName, _)):
				Context.error('${typedApiName} expects a module type reference (class/extern), not a string literal. '
					+ 'Wrap pure Elixir modules as externs and pass that type, or use ${unsafeApiName}("${moduleName}") explicitly.',
					moduleRef.pos);
				return moduleName;
			default:
		}

		var resolvedType:Type = null;
		var typedExpr:TypedExpr = null;
		try {
			typedExpr = Context.typeExpr(normalizedExpr);
			resolvedType = typedExpr.t;
		} catch (_:Any) {
			Context.error('${typedApiName} could not resolve the provided module reference. '
				+ 'Pass a class/extern type reference (for example, EndpointExtern).',
				moduleRef.pos);
			return "";
		}

		var moduleName = switch (typedExpr.expr) {
			case TTypeExpr(moduleType):
				moduleNameFromModuleType(moduleType);
			default:
				moduleNameFromType(resolvedType);
		};
		if (moduleName == null || moduleName == "") {
			var dottedPath = extractDotPath(normalizedExpr);
			if (dottedPath != null) {
				try {
					moduleName = moduleNameFromType(Context.getType(dottedPath));
				} catch (_:Any) {
					// Keep canonical diagnostic below.
				}
			}
		}
		if (moduleName == null || moduleName == "") {
			Context.error('${typedApiName} requires a module type reference (Class<...>). '
				+ 'For existing pure Elixir modules, add an extern wrapper with @:native and pass that type.',
				moduleRef.pos);
		}
		return moduleName;
	}
	#end
}
