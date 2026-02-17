package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using StringTools;
#end

/**
 * Macro helpers for LiveSocket assign operations.
 *
 * WHAT
 * - Provides compile-time handling for:
 *   - `LiveSocket.assign(_.field, value)`
 *   - `LiveSocket.assign({...})` (Phoenix assign/2 map form)
 *   - `LiveSocket.assignNew(_.field, fn)`
 *   - `LiveSocket.update(_.field, fn)`
 *   - `LiveSocket.merge({...})` (compat alias)
 *
 * WHY
 * - Macro shorthand keeps call sites short and close to Phoenix style.
 * - We still validate field names against the assigns type at compile time.
 * - We rewrite Haxe field names to Phoenix atom keys (`camelCase` -> `snake_case`).
 *
 * HOW
 * - Reads assigns type `T` from `LiveSocket<T>`.
 * - Verifies referenced field names exist on `T`.
 * - Rewrites names to snake_case and emits `phoenix.Component.*` calls.
 */
#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class AssignMacro {
	#if macro
	/**
	 * Process assign operation with Phoenix-style arities.
	 *
	 * Haxe:
	 *   socket.assign(_.editingTodo, todo)
	 *   socket.assign({editing_todo: todo, show_form: true})
	 *
	 * Elixir:
	 *   assign(socket, :editing_todo, todo)
	 *   assign(socket, %{editing_todo: todo, show_form: true})
	 */
	public static function processAssign(socketExpr:Expr, fieldOrUpdates:Expr, ?value:Expr):Expr {
		var fieldName = extractFieldName(fieldOrUpdates);
		if (value == null || isNullExpr(value)) {
			if (fieldName != null) {
				var assignsType = extractAssignsType(socketExpr);
				validateFieldExists(assignsType, fieldName, fieldOrUpdates.pos);
				var atomKeyExpr:Expr = macro(($v{camelToSnake(fieldName)} : elixir.types.Atom));
				var nullValue = value == null ? macro null : value;
				return macro phoenix.Component.assign($socketExpr, $e{atomKeyExpr}, $nullValue);
			}
			return switch (fieldOrUpdates.expr) {
				case EObjectDecl(_):
					processMerge(socketExpr, fieldOrUpdates);
				case _:
					macro phoenix.Component.assign($socketExpr, $fieldOrUpdates);
			}
		}

		if (fieldName == null) {
			return macro phoenix.Component.assign($socketExpr, $fieldOrUpdates, $value);
		}

		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldOrUpdates.pos);

		var atomKeyExpr:Expr = macro(($v{camelToSnake(fieldName)} : elixir.types.Atom));
		return macro phoenix.Component.assign($socketExpr, $e{atomKeyExpr}, $value);
	}

	private static function isNullExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CIdent("null")):
				true;
			case _:
				false;
		}
	}

	/**
	 * Process an assign_new operation.
	 */
	public static function processAssignNew(socketExpr:Expr, fieldExpr:Expr, defaultFn:Expr):Expr {
		var fieldName = extractFieldName(fieldExpr);
		if (fieldName == null) {
			Context.error("Expected field access expression like _.fieldName", fieldExpr.pos);
		}

		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldExpr.pos);

		var atomKeyExpr:Expr = macro(($v{camelToSnake(fieldName)} : elixir.types.Atom));
		return macro phoenix.Component.assignNew($socketExpr, $e{atomKeyExpr}, $defaultFn);
	}

	/**
	 * Process an update operation.
	 */
	public static function processUpdate(socketExpr:Expr, fieldExpr:Expr, updater:Expr):Expr {
		var fieldName = extractFieldName(fieldExpr);
		if (fieldName == null) {
			Context.error("Expected field access expression like _.fieldName", fieldExpr.pos);
		}

		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldExpr.pos);

		var atomKeyExpr:Expr = macro(($v{camelToSnake(fieldName)} : elixir.types.Atom));
		return macro phoenix.Component.update($socketExpr, $e{atomKeyExpr}, $updater);
	}

	/**
	 * Process a batch merge operation.
	 *
	 * Transforms: socket.merge({editingTodo: null, showForm: false})
	 * Into: Phoenix.Component.assign(socket, %{editing_todo: nil, show_form: false})
	 */
	public static function processMerge(socketExpr:Expr, updates:Expr):Expr {
		switch (updates.expr) {
			case EObjectDecl(fields):
				var assignsType = extractAssignsType(socketExpr);
				var transformedFields = [];

				for (field in fields) {
					validateFieldExists(assignsType, field.field, field.expr.pos);
					transformedFields.push({
						field: camelToSnake(field.field),
						expr: field.expr
					});
				}

				var mapExpr:Expr = {expr: EObjectDecl(transformedFields), pos: updates.pos};
				return macro phoenix.Component.assign($socketExpr, $e{mapExpr});

			case _:
				Context.error("Expected object literal with fields to merge", updates.pos);
				return null;
		}
	}

	private static function extractFieldName(expr:Expr):Null<String> {
		switch (expr.expr) {
			case EField({expr: EConst(CIdent("_"))}, field):
				return field;
			case EArray({expr: EConst(CIdent("_"))}, {expr: EConst(CString(field, _))}):
				return field;
			case _:
				return null;
		}
	}

	private static function extractAssignsType(socketExpr:Expr):Type {
		var socketType = Context.typeof(socketExpr);
		return switch (socketType) {
			case TAbstract(reference, params) if (reference.get().name == "LiveSocket" && params.length > 0):
				params[0];
			case TInst(reference, params) if (reference.get().name == "Socket" && params.length > 0):
				params[0];
			case _:
				Context.error("Unable to extract assigns type from socket", socketExpr.pos);
				null;
		};
	}

	private static function validateFieldExists(assignsType:Type, fieldName:String, pos:Position):Void {
		var fields = getTypeFields(assignsType);
		if (fields.exists(fieldName)) {
			return;
		}

		var availableFields = [for (name in fields.keys()) name];
		availableFields.sort((a, b) -> Reflect.compare(a, b));

		var message = 'Field "$fieldName" does not exist in assigns type.\n';
		message += availableFields.length > 0 ? 'Available fields: ${availableFields.join(", ")}' : "The assigns type has no fields.";
		Context.error(message, pos);
	}

	private static function getTypeFields(type:Type):Map<String, Bool> {
		var fields = new Map<String, Bool>();

		switch (type.follow()) {
			case TAnonymous(reference):
				for (field in reference.get().fields) {
					fields.set(field.name, true);
				}
			case TInst(reference, _):
				for (field in reference.get().fields.get()) {
					fields.set(field.name, true);
				}
			case TType(reference, _):
				return getTypeFields(reference.get().type);
			case _:
		}

		return fields;
	}

	/**
	 * Convert camelCase to snake_case.
	 *
	 * This function is intentionally public so assign-key generation macros can
	 * share the exact same key-normalization behavior.
	 */
	public static function camelToSnake(name:String):String {
		if (name.length == 0) {
			return name;
		}

		var result = new StringBuf();
		var previousWasUpper = false;
		for (index in 0...name.length) {
			var character = name.charAt(index);
			var isUpper = character == character.toUpperCase() && character != character.toLowerCase();
			if (index > 0 && isUpper && !previousWasUpper) {
				result.add("_");
			}
			result.add(character.toLowerCase());
			previousWasUpper = isUpper;
		}

		return result.toString();
	}
	#end
}
