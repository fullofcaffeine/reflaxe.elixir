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
 */
function collect(moduleTypes:Array<ModuleType>):Map<String, Bool> {
	var exports:Map<String, Bool> = [];
	for (moduleType in moduleTypes) {
		switch (moduleType) {
			case TClassDecl(classRef):
				var caller = classRef.get();
				if (caller.isExtern)
					continue;
				var callerModule = ModuleBuilder.extractModuleName(caller);
				function record(owner:ClassType, field:ClassField, isStatic:Bool):Void {
					if (owner.isExtern || field.isPublic || ModuleBuilder.extractModuleName(owner) == callerModule)
						return;
					switch (field.kind) {
						case FMethod(_):
							exports.set(key(owner, field, isStatic), true);
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
			case _:
		}
	}
	return exports;
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
