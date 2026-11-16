package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.builders.ModuleBuilder;

/**
 * Finds private Haxe methods that need an Elixir export for a checked remote use.
 *
 * Haxe has already checked access, including `@:allow` and `@:access`. Elixir
 * has no friend visibility: `Reader.read()` calling `Scope.value()` requires
 * `def value`, even when the Haxe declaration stays private. Scan typed field
 * references (including captures) before emitting any class, so class order
 * cannot affect visibility and unused-private pruning keeps these methods.
 * Internal-only methods remain `defp`; this does not change Haxe access rules.
 *
 * With `kept`, each caller class that Haxe did not type again in this request
 * reuses its list from the last published request (see `ClassResultCache`).
 * The list of a caller depends only on its typed body and on the declarations
 * that it references, and Haxe types the caller again when one of them changes.
 * `onCallerScanned` runs once for each caller that was scanned.
 */
function collect(moduleTypes:Array<ModuleType>, ?kept:ClassResultCache<Array<String>>, ?onCallerScanned:Float->Void):Map<String, Bool> {
	var exports:Map<String, Bool> = [];
	if (kept != null)
		kept.begin();
	function scan(caller:ClassType):Array<String> {
		var started = Sys.time();
		var keys = collectForCaller(caller);
		if (onCallerScanned != null)
			onCallerScanned((Sys.time() - started) * 1000.0);
		return keys;
	}
	for (moduleType in moduleTypes) {
		switch (moduleType) {
			case TClassDecl(classRef):
				var caller = classRef.get();
				if (caller.isExtern)
					continue;
				var keys = kept != null ? kept.resultFor(caller, scan) : scan(caller);
				for (identity in keys)
					exports.set(identity, true);
			case _:
		}
	}
	return exports;
}

/** Returns the export keys of private methods in other modules that `caller` uses. */
function collectForCaller(caller:ClassType):Array<String> {
	var keys:Array<String> = [];
	var seen:Map<String, Bool> = [];
	var callerModule = ModuleBuilder.extractModuleName(caller);
	function record(owner:ClassType, field:ClassField, isStatic:Bool):Void {
		if (owner.isExtern || field.isPublic || ModuleBuilder.extractModuleName(owner) == callerModule)
			return;
		switch (field.kind) {
			case FMethod(_):
				var identity = key(owner, field, isStatic);
				if (!seen.exists(identity)) {
					seen.set(identity, true);
					keys.push(identity);
				}
			case FVar(_, _):
		}
	}
	function visit(expr:TypedExpr):Void {
		if (expr == null)
			return;
		switch (expr.expr) {
			case TNew(owner, _, _):
				var target = owner.get();
				if (target.constructor != null)
					record(target, target.constructor.get(), false);
			case TField(_, FStatic(owner, field)):
				record(owner.get(), field.get(), true);
			case TField(_, FInstance(owner, _, field)) | TField(_, FClosure({c: owner}, field)):
				record(owner.get(), field.get(), false);
			case _:
		}
		TypedExprTools.iter(expr, visit);
	}
	for (field in caller.statics.get().concat(caller.fields.get()))
		visit(field.expr());
	if (caller.constructor != null)
		visit(caller.constructor.get().expr());
	visit(caller.init);
	return keys;
}

/** Haxe declaration identity stays stable across macro refs and native renaming. */
function key(owner:ClassType, field:ClassField, isStatic:Bool):String {
	return owner.module + "." + owner.name + (isStatic ? ".static." : ".instance.") + field.name;
}

/**
 * A caller edit can change an unchanged class's native exports. Compare each
 * declaration with the last published compilation so warm builds emit that
 * class again when a remote private use appears or disappears. This adds only
 * target dependency invalidation; Haxe still owns ordinary source invalidation.
 */
function changedForClass(owner:ClassType, current:Map<String, Bool>, previous:Null<Map<String, Bool>>):Bool {
	if (previous == null)
		return false;
	function changed(field:ClassField, isStatic:Bool):Bool {
		var identity = key(owner, field, isStatic);
		return current.exists(identity) != previous.exists(identity);
	}
	for (field in owner.statics.get())
		if (changed(field, true))
			return true;
	for (field in owner.fields.get())
		if (changed(field, false))
			return true;
	return owner.constructor != null && changed(owner.constructor.get(), false);
}
#end
