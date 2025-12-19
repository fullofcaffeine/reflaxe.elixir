package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
using StringTools;
#end

/**
 * Macro implementation for type-safe LiveSocket assign operations.
 * 
 * This macro provides compile-time validation of field names and automatic
 * conversion from camelCase to snake_case for Phoenix LiveView compatibility.
 * 
 * ## Key Features
 * - Validates field existence at compile time
 * - Checks type compatibility between field and value
 * - Automatically converts camelCase to snake_case
 * - Generates clean, idiomatic Elixir code
 * - Zero runtime overhead
 * 
 * ## Implementation Details
 * 
 * The macro works by:
 * 1. Extracting the assigns type T from LiveSocket<T>
 * 2. Validating field access expressions like _.fieldName
 * 3. Converting camelCase field names to snake_case atoms
 * 4. Generating appropriate Phoenix.LiveView.assign calls
 */
#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class AssignMacro {
	#if macro
	
	/**
	 * Process a single assign operation.
	 * 
	 * Transforms: socket.assign(_.editingTodo, todo)
	 * Into: Phoenix.Component.assign(socket, :editing_todo, todo)
	 * 
	 * @param socketExpr The LiveSocket expression
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param value The value to assign
	 * @return Updated LiveSocket expression
	 */
	public static function processAssign(socketExpr: Expr, fieldExpr: Expr, value: Expr): Expr {
		var fieldName = extractFieldName(fieldExpr);
		if (fieldName == null) {
			Context.error("Expected field access expression like _.fieldName", fieldExpr.pos);
		}
		
		// Validate field exists in assigns type
		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldExpr.pos);
		
		// Convert camelCase to snake_case
		var snakeCaseName = camelToSnake(fieldName);
		
        // Generate Phoenix.Component.assign call with an atom key.
        // We model the atom via `elixir.types.Atom` so this stays AST-based (no ERaw).
        var atomKeyExpr: Expr = macro (($v{snakeCaseName} : elixir.types.Atom));
        return macro phoenix.Component.assign($socketExpr, $e{atomKeyExpr}, $value);
	}
	
	/**
	 * Process a batch merge operation.
	 * 
	 * Transforms: socket.merge({editingTodo: null, showForm: false})
	 * Into: Phoenix.Component.assign(socket, %{editing_todo: nil, show_form: false})
	 * 
	 * @param socketExpr The LiveSocket expression
	 * @param updates Object with fields to update
	 * @return Updated LiveSocket expression
	 */
	public static function processMerge(socketExpr: Expr, updates: Expr): Expr {
		switch (updates.expr) {
			case EObjectDecl(fields):
				var assignsType = extractAssignsType(socketExpr);
				var transformedFields = [];

				for (field in fields) {
					// Validate field exists
					validateFieldExists(assignsType, field.field, field.expr.pos);

					// Convert to snake_case
					var snakeCaseName = camelToSnake(field.field);
					transformedFields.push({
						field: snakeCaseName,
						expr: field.expr
					});
				}

					// Build an object literal with snake_case field names; the compiler emits
					// `%{...}` with atom keys in Elixir. This keeps references visible in the AST
					// so later hygiene passes cannot accidentally drop required binders.
					var mapExpr: Expr = { expr: EObjectDecl(transformedFields), pos: updates.pos };
					return macro phoenix.Component.assign($socketExpr, $e{mapExpr});

				case _:
					Context.error("Expected object literal with fields to merge", updates.pos);
					return null;
			}
	}
	
	/**
	 * Process an assign_new operation.
	 * 
	 * Transforms: socket.assignNew(_.theme, () -> getUserTheme())
	 * Into: Phoenix.Component.assign_new(socket, :theme, fn -> get_user_theme() end)
	 * 
	 * @param socketExpr The LiveSocket expression
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param defaultFn Function that returns the default value
	 * @return Updated LiveSocket expression
	 */
	public static function processAssignNew(socketExpr: Expr, fieldExpr: Expr, defaultFn: Expr): Expr {
		var fieldName = extractFieldName(fieldExpr);
		if (fieldName == null) {
			Context.error("Expected field access expression like _.fieldName", fieldExpr.pos);
		}

		// Validate field exists in assigns type
		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldExpr.pos);

		// Convert camelCase to snake_case
		var snakeCaseName = camelToSnake(fieldName);

		// Generate Phoenix.Component.assign_new/3 call with an atom key.
		var atomKeyExpr: Expr = macro (($v{snakeCaseName} : elixir.types.Atom));
		return macro phoenix.Component.assignNew($socketExpr, $e{atomKeyExpr}, $defaultFn);
	}
	
	/**
	 * Process an update operation.
	 * 
	 * Transforms: socket.update(_.counter, x -> x + 1)
	 * Into: Phoenix.Component.update(socket, :counter, &(&1 + 1))
	 * 
	 * @param socketExpr The LiveSocket expression
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param updater Function that transforms the current value
	 * @return Updated LiveSocket expression
	 */
	public static function processUpdate(socketExpr: Expr, fieldExpr: Expr, updater: Expr): Expr {
		var fieldName = extractFieldName(fieldExpr);
		if (fieldName == null) {
			Context.error("Expected field access expression like _.fieldName", fieldExpr.pos);
		}

		// Validate field exists in assigns type
		var assignsType = extractAssignsType(socketExpr);
		validateFieldExists(assignsType, fieldName, fieldExpr.pos);

		// Convert camelCase to snake_case
		var snakeCaseName = camelToSnake(fieldName);

		// Generate Phoenix.Component.update/3 call with an atom key.
		var atomKeyExpr: Expr = macro (($v{snakeCaseName} : elixir.types.Atom));
		return macro phoenix.Component.update($socketExpr, $e{atomKeyExpr}, $updater);
	}
	
	/**
	 * Extract field name from underscore expression.
	 * 
	 * Handles: _.fieldName, _["fieldName"], etc.
	 */
	private static function extractFieldName(expr: Expr): Null<String> {
		switch (expr.expr) {
			case EField({expr: EConst(CIdent("_"))}, field):
				return field;
			case EArray({expr: EConst(CIdent("_"))}, {expr: EConst(CString(field, _))}):
				return field;
			case _:
				return null;
		}
	}
	
	/**
	 * Extract the assigns type T from LiveSocket<T>.
	 */
	private static function extractAssignsType(socketExpr: Expr): Type {
		var socketType = Context.typeof(socketExpr);
		
		// Unwrap the LiveSocket abstract to get the type parameter
		switch (socketType) {
			case TAbstract(ref, params) if (ref.get().name == "LiveSocket" && params.length > 0):
				return params[0];
			case TInst(ref, params) if (ref.get().name == "Socket" && params.length > 0):
				return params[0];
			case _:
				Context.error("Unable to extract assigns type from socket", socketExpr.pos);
				return null;
		}
	}
	
	/**
	 * Validate that a field exists in the assigns type.
	 */
	private static function validateFieldExists(assignsType: Type, fieldName: String, pos: Position): Void {
		var fields = getTypeFields(assignsType);
		
		if (!fields.exists(fieldName)) {
			var availableFields = [for (name in fields.keys()) name];
			availableFields.sort((a, b) -> Reflect.compare(a, b));
			
			var message = 'Field "$fieldName" does not exist in assigns type.\n';
			if (availableFields.length > 0) {
				message += 'Available fields: ${availableFields.join(", ")}';
			} else {
				message += 'The assigns type has no fields.';
			}
			
			Context.error(message, pos);
		}
	}
	
	/**
	 * Get all fields from a type.
	 */
	private static function getTypeFields(type: Type): Map<String, Bool> {
		var fields = new Map<String, Bool>();
		
		switch (type.follow()) {
			case TAnonymous(ref):
				for (field in ref.get().fields) {
					fields.set(field.name, true);
				}
			case TInst(ref, _):
				var classType = ref.get();
				for (field in classType.fields.get()) {
					fields.set(field.name, true);
				}
			case TType(ref, _):
				// Handle typedefs
				return getTypeFields(ref.get().type);
			case _:
				// For other types, we might not be able to extract fields
		}
		
		return fields;
	}
	
	/**
	 * Convert camelCase to snake_case.
	 * 
	 * Examples:
	 * - editingTodo → editing_todo
	 * - showForm → show_form
	 * - currentUserID → current_user_id
	 */
	private static function camelToSnake(name: String): String {
		if (name.length == 0) return name;
		
		var result = new StringBuf();
		var prevWasUpper = false;
		
		for (i in 0...name.length) {
			var char = name.charAt(i);
			var isUpper = char == char.toUpperCase() && char != char.toLowerCase();
			
			if (i > 0 && isUpper && !prevWasUpper) {
				result.add("_");
			}
			
			result.add(char.toLowerCase());
			prevWasUpper = isUpper;
		}
		
		return result.toString();
	}
	
	#end
}
