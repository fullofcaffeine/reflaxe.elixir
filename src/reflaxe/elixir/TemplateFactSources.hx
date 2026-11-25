package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.ReflectCompiler;
import reflaxe.elixir.ast.NameUtils;

using reflaxe.helpers.ModuleTypeHelper;

/** Metadata of a template registry, and the read of each kind (`TemplateFactReads`). **/
private final REGISTRY_READS = [
	":phxHookNames" => TemplateFactReads.HOOK_NAMES,
	":phxEventNames" => TemplateFactReads.EVENT_NAMES,
	":hxxHtmlTags" => TemplateFactReads.HTML_TAGS
];

/** Metadata of a class whose functions the component index reads. **/
private final COMPONENT_CLASS_METAS = [":component", ":phoenix.components"];

/** Metadata of one component function in such a class. **/
private final COMPONENT_FUNCTION_META = ":component";

/**
 * One type that a template check reads without a Haxe dependency, and the
 * reads that see it (`TemplateFactReads`). Example: the props typedef of the
 * component function `badge` has the read `component:badge`; a template that
 * looks up `<.badge>` makes that read.
 */
typedef TemplateFact = {
	final moduleType:ModuleType;
	final reads:Array<String>;
}

/**
 * Returns each type in `moduleTypes` that a HEEx template check reads without
 * a Haxe dependency, by `ReflectCompiler.typeKey`, with the reads that see it
 * (`TemplateFactReads`).
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
 *   result, so Reflaxe compares the text of these files between requests. An
 *   edit outside the classes of any other file (a comment, a typedef field, a
 *   new typedef) builds only the types that Haxe typed again.
 * - After an edit outside the classes of one of these files, a warm request
 *   builds the types that Haxe typed again and each type whose last build
 *   read a fact that changed (`TemplateFactReads.buildsForChangedFacts`).
 *   Before, it built every type. Example: in the todo-app, `TodoTypes.hx`
 *   holds `TodoSort`, which the props of the layout components reach. An edit
 *   of any typedef in it built 141 classes; now it builds the 6 that Haxe
 *   typed again, because no template looks up a layout component.
 *
 * WHICH types, and the reader of each
 * - A type with `@:phxHookNames`, `@:phxEventNames` or `@:hxxHtmlTags`: the
 *   registries of `HeexAssignsTypeLinterTransforms` and
 *   `HeexInlineMarkupConstStringRefsTransforms`.
 * - A class with `@:component` or `@:phoenix.components`: the component index
 *   of `HeexAssignsTypeLinterTransforms.buildComponentFunctionIndex`. Its read
 *   is `component:<name>` for each of its component functions.
 * - Each enum, typedef and abstract that the type of a `@:component` function
 *   of such a class reaches, in any file. The index reads the props of a
 *   component through these types. Example: `badge(assigns:BadgeAssigns)`
 *   with `typedef BadgeAssigns = {label:String}` in `Types.hx` makes
 *   `Types.hx` one of these files, and gives `BadgeAssigns` the read
 *   `component:badge`.
 *
 * LIMITS
 * - Any compiler path that reads a type by name, without a Haxe reference
 *   from the class being built, needs one of two things. Either Haxe records
 *   the dependency while it types that class, as `RouterContractDependencies`
 *   does for a router's `paramsContract`, or the type is added here.
 *   Otherwise a warm build can keep old output or old diagnostics.
 * - An edit inside a registry class or a component class is class text, so
 *   its file text does not change. `TemplateFactReads` still finds a changed
 *   fact there, because Reflaxe asks it on every warm request and Haxe types
 *   the edited class again, which gives it a new fingerprint.
 * - Std and framework types that a template check reads by name, such as
 *   `phoenix.Phoenix.Form` and `phoenix.Phoenix.FormField` for a `:let`
 *   binding of a form, are not listed here. They change only with the
 *   compiler's library; restart the watcher after such a change.
 */
function collect(moduleTypes:Array<ModuleType>):Map<String, TemplateFact> {
	var facts = new Map<String, TemplateFact>();
	function add(moduleType:ModuleType, base:BaseType, read:Null<String>):Bool {
		var key = ReflectCompiler.typeKey(base);
		var fact = facts.get(key);
		var isNew = fact == null;
		if (fact == null) {
			fact = {moduleType: moduleType, reads: []};
			facts.set(key, fact);
		}
		if (read != null && fact.reads.indexOf(read) == -1)
			fact.reads.push(read);
		return isNew;
	}
	for (moduleType in moduleTypes) {
		var base = moduleType.getCommonData();
		for (meta => read in REGISTRY_READS) {
			if (base.meta.has(meta))
				add(moduleType, base, read);
		}
		switch (moduleType) {
			case TClassDecl(classRef):
				var classType = classRef.get();
				if (!hasAnyMeta(classType, COMPONENT_CLASS_METAS))
					continue;
				add(moduleType, classType, null);
				for (field in classType.statics.get()) {
					if (!field.meta.has(COMPONENT_FUNCTION_META))
						continue;
					// The component index keys a function by this name
					// (`HeexAssignsTypeLinterTransforms.buildComponentFunctionIndex`).
					var read = TemplateFactReads.componentRead(NameUtils.toSnakeCase(field.name));
					add(moduleType, classType, read);
					addReachedDeclarations(field.type, read, add);
				}
			case _:
		}
	}
	return facts;
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
private function addReachedDeclarations(type:Type, read:String, add:(ModuleType, BaseType, Null<String>) -> Bool):Void {
	// A declaration that this walk entered already is not entered again, so a
	// recursive typedef ends. Another component's walk may enter it again to
	// add its own read.
	var entered = new Map<String, Bool>();
	function enter(moduleType:ModuleType, base:BaseType):Bool {
		add(moduleType, base, read);
		var key = ReflectCompiler.typeKey(base);
		if (entered.exists(key))
			return false;
		entered.set(key, true);
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
				var anonType = anonymous.get();
				// `Base & {...}` and `{> Base, ...}` copy the fields of `Base`,
				// but an edit of `Base` is in Base's file: enter it too, so that
				// its file is compared and its fingerprint checked.
				switch (anonType.status) {
					case AExtend(extended):
						for (extendedType in extended.get())
							visit(extendedType);
					case _:
				}
				for (field in anonType.fields)
					visit(field.type);
			case TInst(_, params):
				for (param in params)
					visit(param);
			case TEnum(enumRef, params):
				enter(TEnumDecl(enumRef), enumRef.get());
				for (param in params)
					visit(param);
			case TType(defRef, params):
				var definition = defRef.get();
				if (enter(TTypeDecl(defRef), definition))
					visit(definition.type);
				for (param in params)
					visit(param);
			case TAbstract(abstractRef, params):
				var abstractType = abstractRef.get();
				if (enter(TAbstract(abstractRef), abstractType))
					visit(abstractType.type);
				for (param in params)
					visit(param);
		}
	}
	visit(type);
}
#end
