package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.ReflectCompiler;
import reflaxe.elixir.TemplateFactSources.TemplateFact;

using reflaxe.helpers.ModuleTypeHelper;

/**
 * Records which template facts each type's build reads, so that a warm
 * compilation-server request builds again only the templates whose facts
 * changed.
 *
 * WHAT IS A TEMPLATE FACT
 * - A HEEx template check reads some types by name, not through a Haxe
 *   reference: `phx-hook="Ping"` is checked against every `@:phxHookNames`
 *   registry, and `<.badge label="x">` against the props of the `@:component`
 *   function `badge`. `TemplateFactSources` lists these types; each has one
 *   or more reads, such as `registry:hooks` or `component:badge`.
 * - Haxe does not type a template's class again when such a type changes,
 *   because the class does not refer to it.
 *
 * WHY THIS EXISTS
 * - Before, an edit of an enum, typedef or abstract in a file with a template
 *   fact built every type again. In the todo-app, `TodoTypes.hx` holds an enum
 *   that the props of a layout component reach, so an edit of any typedef in
 *   it built all 141 classes (about 11.3 s at a load of 15 to 21), although Haxe
 *   typed only 6 of them again.
 * - Now each build records the reads that its template checks make
 *   (`note`), and a warm request builds a type that Haxe did not type again
 *   only when one of its recorded reads sees a template fact that changed
 *   (`buildsForChangedFacts`).
 *
 * WHEN A RECORD IS CORRECT
 * - A type's output depends on template facts only through its template
 *   checks, and each check calls `note` before it reads a fact or a cache
 *   that holds facts. A record therefore lists every read that the last
 *   published build of the type made. A type that the cache filter leaves out
 *   keeps its output, so it keeps its record.
 * - A fact changed when its `fingerprint` differs from the one of the last
 *   publication. The fingerprint holds every part of the declaration that a
 *   template check can read, except source positions, which no check reads.
 *   A fact that Haxe did not type again is the same object as at the last
 *   publication, so its fingerprint is reused instead of computed again.
 * - Records and fingerprints change only after the output was published
 *   (`commit`), so a failed request compares with the last published state.
 * - A type without a record counts as a reader of every fact. A read that
 *   no build owns (`note` outside `beginBuild`/`endBuild`) drops every record,
 *   so the next change of a fact builds every type again, as before.
 *
 * WHAT IS NOT COVERED
 * - Only a change that the vendored Reflaxe cache filter reports calls
 *   `buildsForChangedFacts`: an edit outside the classes of a file that
 *   declares an enum, typedef or abstract with a template fact. An edit inside
 *   a registry class or a component class builds only what Haxe typed again,
 *   as before this file existed.
 * - Any other read of a type by name must still be a Haxe dependency of the
 *   class being built, or a template fact (see `TemplateFactSources`).
 */
class TemplateFactReads {
	/** The read of the `@:phxHookNames` registries. **/
	public static inline final HOOK_NAMES = "registry:hooks";

	/** The read of the `@:phxEventNames` registries. **/
	public static inline final EVENT_NAMES = "registry:events";

	/** The read of the `@:hxxHtmlTags` registries. **/
	public static inline final HTML_TAGS = "registry:htmlTags";

	/** The read of the whole component index, for example for tooling. **/
	public static inline final ALL_COMPONENTS = "component:*";

	static inline final COMPONENT_PREFIX = "component:";

	/**
	 * The reads of each type's last published build, by `ReflectCompiler.typeKey`.
	 * A type without an entry counts as a reader of every fact.
	 */
	@:persistent static var publishedReads:Map<String, Array<String>> = new Map();

	/** The template facts of the last publication, by `ReflectCompiler.typeKey`. **/
	@:persistent static var publishedFacts:Map<String, PublishedFact> = new Map();

	/** The reads of the types that this request built. **/
	static var requestReads:Map<String, Map<String, Bool>> = new Map();

	/** The template facts of this request; null before `beginRequest`. **/
	static var requestFacts:Null<Map<String, PublishedFact>> = null;

	/** The type whose output passes run now, or null between builds. **/
	static var currentBuildKey:Null<String> = null;

	/** True when a template check read a fact outside a build in this request. **/
	static var unattributedRead = false;

	/**
	 * Returns the read of the component index entry `indexKey`: the snake_case
	 * name under which `HeexAssignsTypeLinterTransforms` indexes a component
	 * function, for example `component:badge` for `<.badge>`.
	 */
	public static function componentRead(indexKey:String):String {
		return COMPONENT_PREFIX + indexKey;
	}

	/**
	 * Starts a request with this request's template facts. Computes the
	 * fingerprint of each fact that Haxe typed since the last publication, or
	 * that has no fingerprint yet; reuses the published one for every other.
	 */
	public static function beginRequest(facts:Map<String, TemplateFact>):Void {
		requestReads = new Map();
		currentBuildKey = null;
		unattributedRead = false;
		var current = new Map<String, PublishedFact>();
		for (key => fact in facts) {
			var published = publishedFacts.get(key);
			var reusable = published != null && !ReflectCompiler.wasTypedSinceLastPublication(fact.moduleType.getCommonData());
			var fingerprintText = reusable && published != null ? published.fingerprint : fingerprint(fact.moduleType);
			current.set(key, {fingerprint: fingerprintText, reads: fact.reads.copy()});
		}
		requestFacts = current;
	}

	/**
	 * Marks `key` as built in this request. A built type that makes no read
	 * then gets an empty record at `commit`, so a later change of a fact does
	 * not build it again.
	 */
	public static function markBuilt(key:String):Void {
		if (!requestReads.exists(key))
			requestReads.set(key, new Map());
	}

	/** Starts the output passes of the type with `key` (see `note`). **/
	public static function beginBuild(key:String):Void {
		markBuilt(key);
		currentBuildKey = key;
	}

	/** Ends the output passes that `beginBuild` started. **/
	public static function endBuild():Void {
		currentBuildKey = null;
	}

	/**
	 * Records that the type being built reads the template facts of `read`.
	 * A template check calls it before it reads a registry, the component
	 * index, or a cache that holds a result computed from them.
	 */
	public static function note(read:String):Void {
		var key = currentBuildKey;
		if (key == null) {
			unattributedRead = true;
			return;
		}
		var reads = requestReads.get(key);
		if (reads == null) {
			reads = new Map();
			requestReads.set(key, reads);
		}
		reads.set(read, true);
	}

	/**
	 * Returns the types that must be built again because a template fact
	 * changed since the last publication: each type in `liveKeys` whose
	 * recorded reads see a changed fact, and each type without a record.
	 * `readerCount` receives the number of types with a record among them.
	 */
	public static function buildsForChangedFacts(liveKeys:Array<String>, readerCount:Int->Void):Map<String, Bool> {
		var changed = changedReads();
		var builds = new Map<String, Bool>();
		var readers = 0;
		for (key in liveKeys) {
			var reads = publishedReads.get(key);
			if (reads == null) {
				builds.set(key, true);
			} else if (seesAny(reads, changed)) {
				builds.set(key, true);
				readers++;
			}
		}
		readerCount(readers);
		return builds;
	}

	/**
	 * Makes this request's records and facts the published ones. Call it only
	 * after the output was published. A type that this request left out keeps
	 * its record.
	 */
	public static function commit():Void {
		if (unattributedRead) {
			publishedReads = new Map();
		} else {
			for (key => reads in requestReads)
				publishedReads.set(key, [for (read in reads.keys()) read]);
		}
		var facts = requestFacts;
		if (facts != null)
			publishedFacts = facts;
		requestReads = new Map();
		requestFacts = null;
	}

	/**
	 * Returns the reads of every fact whose fingerprint differs from the last
	 * publication, and of every fact that was added or removed since then.
	 * Both the published and the current reads of a changed fact count: a
	 * template that read the old fact and one that reads the new fact must
	 * both be checked again.
	 */
	static function changedReads():Map<String, Bool> {
		var changed = new Map<String, Bool>();
		function addReads(fact:Null<PublishedFact>):Void {
			if (fact != null)
				for (read in fact.reads)
					changed.set(read, true);
		}
		var requested = requestFacts;
		var current = requested != null ? requested : new Map<String, PublishedFact>();
		for (key => fact in current) {
			var published = publishedFacts.get(key);
			if (published == null || published.fingerprint != fact.fingerprint) {
				addReads(fact);
				addReads(published);
			}
		}
		for (key => published in publishedFacts) {
			if (!current.exists(key))
				addReads(published);
		}
		return changed;
	}

	static function seesAny(reads:Array<String>, changed:Map<String, Bool>):Bool {
		for (read in reads) {
			if (changed.exists(read))
				return true;
			if (read == ALL_COMPONENTS) {
				for (changedRead in changed.keys())
					if (StringTools.startsWith(changedRead, COMPONENT_PREFIX))
						return true;
			}
		}
		return false;
	}

	/**
	 * Returns a text that holds every part of a declaration that a template
	 * check can read: the path, the kind, the type parameters, the metadata,
	 * the documentation, the fields with their types and metadata, the
	 * constructors of an enum, the underlying type of a typedef or an
	 * abstract, and the value of each variable field (the names of an enum
	 * abstract registry live there).
	 *
	 * Left out: source positions, which no template check reads, the bodies
	 * of methods, which no template check reads either, and Reflaxe's own
	 * `@:reflaxe.typedIn` metadata, which changes each time Haxe types the type.
	 * A named type that the declaration refers to is written by its path; when a
	 * template check reads into it, it is a template fact of its own
	 * (`TemplateFactSources` adds each declaration that component props reach).
	 *
	 * Example: adding `var size:String;` to the props typedef of `badge`
	 * changes the text, and a comment above the typedef does not.
	 */
	public static function fingerprint(moduleType:ModuleType):String {
		var out = new StringBuf();
		switch (moduleType) {
			case TClassDecl(classRef):
				writeClass(classRef.get(), out);
			case TEnumDecl(enumRef):
				var enumType = enumRef.get();
				out.add("enum ");
				writeBase(enumType, out);
				for (name in enumType.names) {
					var construct = enumType.constructs.get(name);
					if (construct == null)
						continue;
					out.add("|ctor " + construct.name + "#" + construct.index + ":");
					writeType(construct.type, out);
					writeParams(construct.params, out);
					writeMeta(construct.meta.get(), out);
					writeDoc(construct.doc, out);
				}
			case TTypeDecl(defRef):
				var defType = defRef.get();
				out.add("typedef ");
				writeBase(defType, out);
				out.add("=");
				writeType(defType.type, out);
			case TAbstract(abstractRef):
				var abstractType = abstractRef.get();
				out.add("abstract ");
				writeBase(abstractType, out);
				out.add("(");
				writeType(abstractType.type, out);
				out.add(")");
				for (from in abstractType.from) {
					out.add("|from ");
					writeType(from.t, out);
					var castField = from.field;
					out.add(castField != null ? "@" + castField.name : "");
				}
				for (to in abstractType.to) {
					out.add("|to ");
					writeType(to.t, out);
					var castField = to.field;
					out.add(castField != null ? "@" + castField.name : "");
				}
				var impl = abstractType.impl;
				if (impl != null) {
					out.add("|impl ");
					writeClass(impl.get(), out);
				}
		}
		return out.toString();
	}

	static function writeBase(base:BaseType, out:StringBuf):Void {
		out.add(base.module + ":" + base.pack.join(".") + "." + base.name);
		out.add(base.isPrivate ? " private" : "");
		out.add(base.isExtern ? " extern" : "");
		writeParams(base.params, out);
		writeMeta(base.meta.get(), out);
		writeDoc(base.doc, out);
	}

	static function writeClass(classType:ClassType, out:StringBuf):Void {
		out.add("class ");
		writeBase(classType, out);
		out.add("|kind " + classKindText(classType.kind));
		out.add(classType.isInterface ? " interface" : "");
		out.add(classType.isFinal ? " final" : "");
		var superClass = classType.superClass;
		if (superClass != null) {
			out.add("|extends ");
			writeTypeRef(superClass.t.get(), superClass.params, out);
		}
		for (implemented in classType.interfaces) {
			out.add("|implements ");
			writeTypeRef(implemented.t.get(), implemented.params, out);
		}
		for (field in classType.statics.get()) {
			out.add("|static ");
			writeField(field, out);
		}
		for (field in classType.fields.get()) {
			out.add("|member ");
			writeField(field, out);
		}
		var constructor = classType.constructor;
		if (constructor != null) {
			out.add("|new ");
			writeField(constructor.get(), out);
		}
	}

	/** Writes the kind of a class; a referenced type is written by its path. **/
	static function classKindText(kind:ClassKind):String {
		return switch (kind) {
			case KNormal: "normal";
			case KTypeParameter(_): "typeParameter";
			case KModuleFields(module): "moduleFields " + module;
			case KExpr(expr): "expr " + ExprTools.toString(expr);
			case KGeneric: "generic";
			case KGenericInstance(classRef, _): "genericInstance " + classRef.toString();
			case KMacroType: "macroType";
			case KAbstractImpl(abstractRef): "abstractImpl " + abstractRef.toString();
			case KGenericBuild: "genericBuild";
		}
	}

	static function writeField(field:ClassField, out:StringBuf):Void {
		out.add(field.name + (field.isPublic ? " public" : "") + (field.isExtern ? " extern" : "") + (field.isFinal ? " final" : ""));
		out.add(" " + Std.string(field.kind) + ":");
		writeType(field.type, out);
		writeParams(field.params, out);
		writeMeta(field.meta.get(), out);
		writeDoc(field.doc, out);
		#if macro
		if (field.kind.match(FVar(_, _))) {
			var expr = field.expr();
			if (expr != null)
				out.add("=" + TypedExprTools.toString(expr));
		}
		#end
		for (overloaded in field.overloads.get()) {
			out.add("|overload ");
			writeField(overloaded, out);
		}
	}

	static function writeParams(params:Array<TypeParameter>, out:StringBuf):Void {
		if (params.length == 0)
			return;
		out.add("<");
		for (param in params) {
			out.add(param.name + ":");
			writeType(param.t, out);
			out.add(",");
		}
		out.add(">");
	}

	static function writeMeta(entries:Array<MetadataEntry>, out:StringBuf):Void {
		for (entry in entries) {
			if (entry.name == ":reflaxe.typedIn")
				continue;
			out.add("@" + entry.name);
			var params = entry.params;
			if (params != null) {
				out.add("(");
				for (param in params)
					out.add(ExprTools.toString(param) + ",");
				out.add(")");
			}
		}
	}

	static function writeDoc(doc:Null<String>, out:StringBuf):Void {
		if (doc != null)
			out.add("/**" + doc + "*/");
	}

	static function writeTypeRef(base:BaseType, params:Array<Type>, out:StringBuf):Void {
		out.add(base.module + ":" + base.pack.join(".") + "." + base.name);
		if (params.length == 0)
			return;
		out.add("<");
		for (param in params) {
			writeType(param, out);
			out.add(",");
		}
		out.add(">");
	}

	/**
	 * Writes a type. A named type is written by its path and its parameters;
	 * an anonymous structure is written with each field, in Haxe's order.
	 */
	static function writeType(type:Null<Type>, out:StringBuf):Void {
		switch (type) {
			case null:
				out.add("null");
			case TMono(ref):
				var resolved = ref.get();
				if (resolved == null)
					out.add("?");
				else
					writeType(resolved, out);
			case TLazy(resolve):
				writeType(resolve(), out);
			case TDynamic(inner):
				out.add("Dynamic<");
				writeType(inner, out);
				out.add(">");
			case TFun(args, result):
				out.add("(");
				for (arg in args) {
					out.add((arg.opt ? "?" : "") + arg.name + ":");
					writeType(arg.t, out);
					out.add(",");
				}
				out.add(")->");
				writeType(result, out);
			case TAnonymous(anonymous):
				out.add("{");
				for (field in anonymous.get().fields) {
					writeField(field, out);
					out.add(";");
				}
				out.add("}");
			case TInst(classRef, params):
				writeTypeRef(classRef.get(), params, out);
			case TEnum(enumRef, params):
				writeTypeRef(enumRef.get(), params, out);
			case TType(defRef, params):
				writeTypeRef(defRef.get(), params, out);
			case TAbstract(abstractRef, params):
				writeTypeRef(abstractRef.get(), params, out);
		}
	}
}

/** A template fact as it was published: its fingerprint and its reads. **/
typedef PublishedFact = {
	final fingerprint:String;
	final reads:Array<String>;
}
#end
