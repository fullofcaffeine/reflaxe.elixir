package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Expr.Position;
import haxe.macro.Context;
import haxe.macro.TypeTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.builders.ModuleBuilder;
import reflaxe.elixir.CompilationContext;

using reflaxe.helpers.ClassFieldHelper;

/**
 * ConstructorBuilder: Handles constructor call compilation (TNew)
 * 
 * WHY: Centralizes constructor transformation logic from ElixirASTBuilder
 * - Extracts ~65 lines of constructor handling logic
 * - Handles Ecto schemas, Maps, and regular classes differently
 * - Manages instance method detection
 * - Determines struct vs constructor function generation
 * 
 * WHAT: Transforms Haxe TNew to appropriate Elixir structures
 * - Ecto schemas → Struct literals %ModuleName{}
 * - Map types → Empty maps %{}
 * - Classes with methods → Module.new() calls
 * - Data classes → Struct literals
 * 
 * HOW: Pattern detection based on class metadata and fields
 * - Check for @:schema annotation for Ecto models
 * - Detect Map types by class name
 * - Analyze fields to find instance methods
 * - Check for constructor presence
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on constructor transformations
 * - Open/Closed: Easy to add new constructor patterns
 * - Testability: Constructor patterns testable independently
 * - Maintainability: ~65 lines extracted to focused module
 * - Performance: Pattern detection optimized in one place
 * 
 * EDGE CASES:
 * - Empty constructors → Empty structs/maps
 * - @:native metadata → Use native module name
 * - StringMap/IntMap → Regular Elixir maps
 * - Classes without methods → Struct literals
 * - Classes with methods → Module.new() calls
 */
@:nullSafety(Off)
class ConstructorBuilder {
	/**
	 * Build constructor call expression
	 * 
	 * WHY: Constructors in Haxe map to different Elixir patterns
	 * WHAT: Detects class type and generates appropriate construction
	 * HOW: Analyze class metadata and fields
	 * 
	 * @param c Class reference
	 * @param params Type parameters (unused in Elixir)
	 * @param el Constructor arguments
	 * @param context Compilation context
	 * @return ElixirASTDef for the constructor call
	 */
	public static function build(c:Ref<ClassType>, params:Array<Type>, el:Array<TypedExpr>, context:CompilationContext, ?pos:Position):Null<ElixirASTDef> {
		var classType = c.get();
		var className = classType.name;
		var moduleName = ModuleBuilder.extractModuleName(classType);

		#if debug_ast_builder
		#if debug_ast_builder trace('[ConstructorBuilder] Building constructor for class: $className'); #end
		#if debug_ast_builder trace('[ConstructorBuilder]   Arguments: ${el.length}'); #end
		#if debug_ast_builder trace('[ConstructorBuilder]   Has @:schema: ${classType.meta.has(":schema")}'); #end
		#end

		// CRITICAL FIX: Bypass compileExpressionImpl to preserve context
		// WHY: compileExpressionImpl creates a FRESH context, losing our flag
		// WHAT: Call ElixirASTBuilder directly with our context to preserve flags
		// HOW: Use buildFromTypedExpr with current context instead of compiler method
		#if debug_ast_builder trace('[ConstructorBuilder] SETTING FLAG isInConstructorArgContext = true'); #end
		context.isInConstructorArgContext = true;

		// Compile arguments directly with our context (not through compiler which creates fresh context)
		var args = [for (e in el) reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context)];

		context.isInConstructorArgContext = false;
		#if debug_ast_builder trace('[ConstructorBuilder] RESET FLAG isInConstructorArgContext = false'); #end

		// Haxe constructor calls normally preserve source defaults at the call site because
		// even a non-extern class may be backed by a target runtime override that exposes
		// only an exact arity. A checked `@:elixirStruct` is different: the compiler owns
		// both its generated `new` definition and its default-bearing Elixir function head,
		// so that explicit native-value ABI can use the natural lower arity safely.
		//
		// Example (Haxe):
		//   new SomeExtern("oops") // where new(message, ?previous, ?native)
		// Elixir (desired):
		//   SomeExtern.new("oops", nil, nil)
		var expectedCtorArgs:Null<Array<{name:String, opt:Bool, t:Type}>> = null;
		var defaultCtorArgExprs:Null<Array<Null<TypedExpr>>> = null;
		var constructorEmitsElixirDefaults = false;
		if (classType.constructor != null) {
			var constructorField = classType.constructor.get();
			switch (TypeTools.follow(constructorField.type)) {
				case TFun(fnArgs, _):
					expectedCtorArgs = fnArgs;
				default:
			}
			var constructorData = constructorField.findFuncData(classType, false);
			if (constructorData != null) {
				defaultCtorArgExprs = [for (arg in constructorData.args) arg.expr];
				constructorEmitsElixirDefaults = !classType.isExtern && classType.meta.has(":elixirStruct");
			}
		}
		if (!constructorEmitsElixirDefaults && expectedCtorArgs != null && args.length < expectedCtorArgs.length) {
			for (i in args.length...expectedCtorArgs.length) {
				if (expectedCtorArgs[i].opt) {
					var defaultExpr = defaultCtorArgExprs != null && i < defaultCtorArgExprs.length ? defaultCtorArgExprs[i] : null;
					args.push(defaultExpr == null ? makeAST(ENil) : reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(defaultExpr, context));
				}
			}
		}

		// ====================================================================
		// PATTERN 1: Ecto Schemas
		// ====================================================================
		if (classType.meta.has(":schema")) {
			#if debug_ast_builder trace('[ConstructorBuilder] ✓ Detected Ecto schema, generating struct literal'); #end
			return buildEctoSchema(moduleName);
		}

		// ====================================================================
		// PATTERN 2: Map Types
		// ====================================================================
		if (isObjectMapType(classType)) {
			context.error(objectMapUnsupportedMessage(), pos);
			return ENil;
		}

		if (isNativeMapType(classType)) {
			#if debug_ast_builder trace('[ConstructorBuilder] ✓ Detected Map type, generating empty map'); #end
			return EMap([]);
		}

		if (isStringType(classType) && args.length == 1) {
			return args[0].def;
		}

		// ====================================================================
		// PATTERN 3: Regular Classes
		// ====================================================================
		var hasInstanceMethods = hasInstanceMethodsCheck(classType);
		var hasConstructor = classType.constructor != null;
		var ctorIsPublic = classType.constructor == null || classType.constructor.get().isPublic;
		var isSameClass = false;
		if (context.currentClass != null) {
			// Reference equality is not reliable across Haxe macro type refs; compare stable identity.
			if (context.currentClass == classType) {
				isSameClass = true;
			} else if (context.currentClass.module == classType.module && context.currentClass.name == classType.name) {
				isSameClass = true;
			}
		}

		#if debug_ast_builder
		#if debug_ast_builder trace('[ConstructorBuilder] Class analysis:'); #end
		#if debug_ast_builder trace('[ConstructorBuilder]   Has instance methods: $hasInstanceMethods'); #end
		#if debug_ast_builder trace('[ConstructorBuilder]   Has constructor: $hasConstructor'); #end
		#end

		// Constructors compile to `new/arity` functions in the module.
		//
		// When a class has a private constructor, Haxe only allows `new Class(...)`
		// within that same class. In Elixir, private functions (`defp new/...`) must be
		// called locally (not as `Module.new(...)`), otherwise Elixir warns/fails with
		// "undefined or private".
		//
		// So:
		// - private ctor + same module: call local `new(...)`
		// - otherwise: call `Module.new(...)`
		var shouldCallLocalNew = hasConstructor && !ctorIsPublic && isSameClass;

		if (shouldCallLocalNew) {
			#if debug_ast_builder trace('[ConstructorBuilder] Generating local new() call (private ctor)'); #end
			return ECall(null, "new", args);
		}

		// Default: call the module's new function: ModuleName.new(args)
		#if debug_ast_builder trace('[ConstructorBuilder] Generating Module.new() call'); #end
		var moduleRef = makeAST(EVar(moduleName));
		return ERemoteCall(moduleRef, "new", args);
	}

	/**
	 * Build Ecto schema struct literal
	 * 
	 * WHY: Ecto schemas use struct literals, not constructor functions
	 * WHAT: Extract module name from metadata and generate struct
	 * HOW: Check @:native metadata for custom module name
	 */
	static function buildEctoSchema(moduleName:String):ElixirASTDef {
		// Generate struct literal: %ModuleName{}
		return EStruct(moduleName, []);
	}

	/**
	 * Check if class name represents a Map type
	 * 
	 * WHY: Map types should generate %{}, not structs
	 * WHAT: Check for common Map class names
	 * HOW: String matching on class name
	 */
	static function isNativeMapType(classType:ClassType):Bool {
		return isHaxeDsClass(classType, "Map")
			|| isHaxeDsClass(classType, "StringMap")
			|| isHaxeDsClass(classType, "IntMap")
			|| isHaxeDsClass(classType, "EnumValueMap");
	}

	static function isObjectMapType(classType:ClassType):Bool {
		return isHaxeDsClass(classType, "ObjectMap");
	}

	static function isHaxeDsClass(classType:ClassType, className:String):Bool {
		return classType != null && classType.name == className && classType.pack != null && classType.pack.join(".") == "haxe.ds";
	}

	static function isStringType(classType:ClassType):Bool {
		return classType != null && classType.name == "String" && classType.pack != null && classType.pack.length == 0;
	}

	static function objectMapUnsupportedMessage():String {
		return "haxe.ds.ObjectMap is not supported on the Elixir target yet: Haxe ObjectMap requires object-identity keys, "
			+ "while BEAM map keys are structural terms. Use StringMap/IntMap/Map for structural keys, or keep ObjectMap behind a target-specific abstraction.";
	}

	/**
	 * Check if class has instance methods
	 * 
	 * WHY: Classes with methods need Module.new(), data classes use structs
	 * WHAT: Analyze class fields for non-static methods
	 * HOW: Iterate fields and check if they're methods and not static
	 */
	static function hasInstanceMethodsCheck(classType:ClassType):Bool {
		for (field in classType.fields.get()) {
			// Instance methods are FMethod that are not in the statics list
			if (field.kind.match(FMethod(_))) {
				// Check if this field is NOT in the statics array
				var isStatic = false;
				for (staticField in classType.statics.get()) {
					if (staticField.name == field.name) {
						isStatic = true;
						break;
					}
				}
				if (!isStatic) {
					return true;
				}
			}
		}
		return false;
	}
}
#end
