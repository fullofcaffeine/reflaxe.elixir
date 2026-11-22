package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;

/**
 * Makes Haxe record that a router module depends on the modules of its
 * `paramsContract` types, while Haxe types the router module.
 *
 * WHY
 * - Haxe never types a router's routes: `AnnotatedModuleEnumerator` replaces
 *   the `final routes = [...]` initializer with `null`, and `@:routes([...])`
 *   is metadata. The compiler reads the routes later and checks each route
 *   with path params against its contract type, which it finds by name
 *   (`Context.getType` in `validatePathParamsContract`).
 * - Without a Haxe reference, Haxe does not type the router again when only
 *   the contract changes. Example: `get("/users/:id", UserController,
 *   UserController.show, {paramsContract: Contracts.UserIdPathParams})` with
 *   no import of `Contracts`. Renaming `id` to `ident` in the typedef makes a
 *   fresh build fail with `paramsContract "Contracts.UserIdPathParams" is
 *   missing field for path param "id"`, but a warm build built only the
 *   typedef's module and passed.
 *
 * HOW
 * - `register` runs in the global build macro, before the routes initializer
 *   is replaced. It finds each `paramsContract` (or `params`) value in the
 *   routes and calls `Context.getType` on its path, resolved through the
 *   module's imports and package like the compiler does. Loading a type from
 *   a build macro adds its module to the dependencies of the module being
 *   built, so an edit of the contract, or of a type that the contract uses,
 *   makes Haxe type the router again, and a warm request builds it again.
 * - A path that does not resolve is left alone here; the compiler reports it
 *   with its usual diagnostic.
 */
private final CONTRACT_OPTION_NAMES = ["paramsContract", "params"];

/**
 * Loads the `paramsContract` types of the routes of `classType` while Haxe
 * types its module (see the module doc). `fields` are the build fields, read
 * before the routes initializer is replaced. Does nothing for a class that is
 * not a router.
 */
function register(classType:ClassType, fields:Array<Field>):Void {
	var classIsRouter = classType.meta.has(":router");
	var routeExprs:Array<Expr> = [];
	for (entry in classType.meta.get())
		addRoutesMetaExpr(entry, routeExprs);
	var fieldIsRouter = false;
	for (field in fields) {
		if (field.meta != null) {
			for (entry in field.meta) {
				if (entry.name == ":router" || entry.name == "router")
					fieldIsRouter = true;
				addRoutesMetaExpr(entry, routeExprs);
			}
		}
		if (field.name != "routes")
			continue;
		switch (field.kind) {
			case FVar(_, initializer) | FProp(_, _, _, initializer):
				if (initializer != null)
					routeExprs.push(initializer);
			case FFun(_):
		}
	}
	if (!classIsRouter && !fieldIsRouter)
		return;
	for (routeExpr in routeExprs)
		loadContracts(classType, routeExpr);
}

private function addRoutesMetaExpr(entry:MetadataEntry, out:Array<Expr>):Void {
	if ((entry.name == ":routes" || entry.name == "routes") && entry.params != null && entry.params.length > 0)
		out.push(entry.params[0]);
}

private function loadContracts(classType:ClassType, routeExpr:Expr):Void {
	function visit(expr:Expr):Void {
		switch (expr.expr) {
			case EObjectDecl(objectFields):
				for (objectField in objectFields) {
					if (CONTRACT_OPTION_NAMES.contains(objectField.field)) {
						var path = dotPath(objectField.expr);
						if (path != null)
							loadType(classType, path);
					}
				}
			case _:
		}
		ExprTools.iter(expr, visit);
	}
	visit(routeExpr);
}

/** Loads the type that `path` names in the module of `classType`, if any. */
private function loadType(classType:ClassType, path:String):Void {
	var resolved = ModuleFieldMetadataRegistry.resolveImportedTypePath(classType, path);
	for (candidate in [resolved, path]) {
		try {
			Context.getType(candidate);
			return;
		} catch (_) {}
	}
}

/** Returns `a.b.C` for the expression `a.b.C`, or null for another expression. */
private function dotPath(expr:Expr):Null<String> {
	return switch (expr.expr) {
		case EConst(CIdent(name)):
			name;
		case EField(target, name):
			var base = dotPath(target);
			base != null ? base + "." + name : null;
		case EParenthesis(inner) | EMeta(_, inner) | ECheckType(inner, _):
			dotPath(inner);
		case _:
			null;
	}
}
#end
