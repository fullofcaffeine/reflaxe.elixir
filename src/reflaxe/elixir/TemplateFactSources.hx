package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.ReflectCompiler;

using reflaxe.helpers.ModuleTypeHelper;

/** Metadata of a template registry: hook names, event names, custom HTML tags. **/
private final REGISTRY_METAS = [":phxHookNames", ":phxEventNames", ":hxxHtmlTags"];

/** Metadata of a class whose functions the component index reads. **/
private final COMPONENT_CLASS_METAS = [":component", ":phoenix.components"];

/** Metadata of one component function in such a class. **/
private final COMPONENT_FUNCTION_META = ":component";

/**
 * Returns the `ReflectCompiler.typeKey` of each type in `moduleTypes` that a
 * HEEx template check reads without a Haxe dependency.
 *
 * WHY
 * - A Haxe compilation server types a module again when its file changes, and
 *   also every module that refers to one of its types. A warm request builds
 *   exactly these types again (`ReflectCompiler.wasTypedSinceLastPublication`).
 * - Template checks also read types that the template's class never names.
 *   `phx-hook="Ping"` is checked against every enum abstract with
 *   `@:phxHookNames`, and `<.badge label="x"/>` against the props typedef of
 *   the `@:component` function `badge`. The class with the template refers to
 *   neither, so Haxe does not type it again when the registry or the props
 *   change. A warm build that built only the edited file would check the
 *   unchanged template against the old facts, and could accept a template
 *   that a fresh build rejects.
 *
 * WHAT
 * - The compiler answers `BaseCompiler.isReadWithoutDependency` with the
 *   result, so an edit of an enum, typedef or abstract in one of these files
 *   still builds every type, as before. An edit outside the classes of any other file (a comment,
 *   a typedef field, a new typedef) builds only the types that Haxe typed again.
 *
 * WHICH types, and the reader of each
 * - A type with `@:phxHookNames`, `@:phxEventNames` or `@:hxxHtmlTags`: the
 *   registries of `HeexAssignsTypeLinterTransforms` and
 *   `HeexInlineMarkupConstStringRefsTransforms`.
 * - A class with `@:component` or `@:phoenix.components`: the component index
 *   of `HeexAssignsTypeLinterTransforms.buildComponentFunctionIndex`.
 * - Each enum, typedef and abstract that the type of a `@:component` function
 *   of such a class reaches, in any file. The index reads the props of a
 *   component through these types. Example: `badge(assigns:BadgeAssigns)`
 *   with `typedef BadgeAssigns = {label:String}` in `Types.hx` makes
 *   `Types.hx` one of these files.
 *
 * LIMITS
 * - Any compiler path that reads a type by name, without a Haxe reference
 *   from the class being built, needs one of two things. Either Haxe records
 *   the dependency while it types that class, as `RouterContractDependencies`
 *   does for a router's `paramsContract`, or the type is added here.
 *   Otherwise a warm build can keep old output or old diagnostics.
 * - An edit inside a registry class or a component class builds only the
 *   types that Haxe typed again, as any class edit does. This is older than
 *   this file and not changed by it.
 */
function collect(moduleTypes:Array<ModuleType>):Map<String, Bool> {
	var keys = new Map<String, Bool>();
	for (moduleType in moduleTypes) {
		var base = moduleType.getCommonData();
		if (hasAnyMeta(base, REGISTRY_METAS))
			keys.set(ReflectCompiler.typeKey(base), true);
		switch (moduleType) {
			case TClassDecl(classRef):
				var classType = classRef.get();
				if (!hasAnyMeta(classType, COMPONENT_CLASS_METAS))
					continue;
				keys.set(ReflectCompiler.typeKey(classType), true);
				for (field in classType.statics.get()) {
					if (field.meta.has(COMPONENT_FUNCTION_META))
						addReachedDeclarations(field.type, keys);
				}
			case _:
		}
	}
	return keys;
}

private function hasAnyMeta(base:BaseType, names:Array<String>):Bool {
	for (name in names) {
		if (base.meta.has(name))
			return true;
	}
	return false;
}

/**
 * Adds the key of each enum, typedef and abstract that `type` reaches: through
 * typedef and abstract definitions, type parameters, function arguments and
 * results, and the fields of anonymous structures. A class is not entered: its
 * fields are class text, which Haxe reports when it changes.
 * A key that is already in `keys` is not entered again, so a recursive typedef
 * ends.
 */
private function addReachedDeclarations(type:Type, keys:Map<String, Bool>):Void {
	function addNew(base:BaseType):Bool {
		var key = ReflectCompiler.typeKey(base);
		if (keys.exists(key))
			return false;
		keys.set(key, true);
		return true;
	}
	function visit(type:Null<Type>):Void {
		if (type == null)
			return;
		switch (type) {
			case TMono(ref):
				visit(ref.get());
			case TLazy(resolve):
				visit(resolve());
			case TDynamic(inner):
				visit(inner);
			case TFun(args, result):
				for (arg in args)
					visit(arg.t);
				visit(result);
			case TAnonymous(anonymous):
				for (field in anonymous.get().fields)
					visit(field.type);
			case TInst(_, params):
				for (param in params)
					visit(param);
			case TEnum(enumRef, params):
				addNew(enumRef.get());
				for (param in params)
					visit(param);
			case TType(defRef, params):
				var definition = defRef.get();
				if (addNew(definition))
					visit(definition.type);
				for (param in params)
					visit(param);
			case TAbstract(abstractRef, params):
				var abstractType = abstractRef.get();
				if (addNew(abstractType))
					visit(abstractType.type);
				for (param in params)
					visit(param);
		}
	}
	visit(type);
}
#end
