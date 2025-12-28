package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.NameUtils;

using StringTools;

/**
 * FieldAccessBuilder: Handles field access expressions and enum constructors
 * 
 * WHY: Separates complex field access logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity (200+ lines of field handling)
 * - Centralizes field access patterns (FStatic, FEnum, FAnon, FInstance)
 * - Handles special cases like enum constructors and atom fields
 * 
 * WHAT: Builds ElixirAST nodes for field access operations
 * - TField expressions with various field access types
 * - Enum constructor references (with/without parameters)
 * - Static field access (including enum abstracts)
 * - Instance and anonymous field access
 * - Special handling for @:elixirIdiomatic enums
 * 
 * HOW: Pattern-based field access compilation
 * - Detects enum constructors and generates appropriate atoms/tuples
 * - Handles enum abstract fields that should be atoms
 * - Manages static field access with proper module references
 * - Transforms field access to idiomatic Elixir patterns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on field access
 * - Open/Closed Principle: Can extend field patterns without modifying core
 * - Testability: Field access logic can be tested independently
 * - Maintainability: Clear boundaries for field-related code
 * - Performance: Optimized field pattern detection
 * 
 * EDGE CASES:
 * - @:elixirIdiomatic enums generate different patterns
 * - Enum constructors with/without parameters differ
 * - Enum abstract fields need special atom detection
 * - Static vs instance field access patterns
 * - Field access on this/self references
 */
@:nullSafety(Off)
class FieldAccessBuilder {
    
    /**
     * Build field access expressions
     * 
     * WHY: Field access is complex with many patterns to handle
     * WHAT: Converts TField to appropriate ElixirAST
     * HOW: Pattern matches on field access type
     * 
     * @param e The object being accessed
     * @param fa The field access type
     * @param context Build context with compilation state
     * @return ElixirASTDef for the field access
     */
    public static function build(e: TypedExpr, fa: FieldAccess, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        // DISABLED: trace('[FieldAccessBuilder] Building field access: ${Type.enumConstructor(fa)}');
        #end
        
        switch(fa) {
            case FEnum(enumType, ef):
                return buildEnumConstructor(enumType, ef, context);
                
            case FStatic(classRef, cf):
                return buildStaticField(e, classRef, cf, context);
                
            case FAnon(cf) | FInstance(_, _, cf):
                return buildInstanceField(e, cf, context);
                
            case FDynamic(fieldName):
                return buildDynamicField(e, fieldName, context);
                
            case FClosure(closureType, cf):
                return buildClosure(e, closureType, cf, context);
                
            default:
                #if debug_ast_builder
                // DISABLED: trace('[FieldAccessBuilder] Unhandled field access type: ${Type.enumConstructor(fa)}');
                #end
                return null;
        }
    }
    
    /**
     * Build enum constructor references
     * 
     * WHY: Enum constructors need special handling for idiomatic patterns
     * WHAT: Generates atoms or tuples based on enum type and parameters
     * HOW: Checks @:elixirIdiomatic and parameter presence
     */
    static function buildEnumConstructor(enumType: Ref<EnumType>, ef: EnumField, context: CompilationContext): ElixirASTDef {
        var enumT = enumType.get();
        
        // Check if this enum is marked as @:elixirIdiomatic
        if (enumT.meta.has("elixirIdiomatic")) {
            // For idiomatic enums, generate atoms instead of tuples
            // OneForOne → :one_for_one
            var atomName = NameUtils.toSnakeCase(ef.name);
            return EAtom(atomName);
        } else {
            // Regular enums: check if constructor has parameters
            // Simple constructors (no params) → :atom
            // Parameterized constructors → {:atom}
            
            // Check if the enum constructor has parameters
            var hasParameters = switch(ef.type) {
                case TFun(args, _): args.length > 0;
                default: false;
            };
            
            var atomName = NameUtils.toSnakeCase(ef.name);
            
            if (hasParameters) {
                // Parameterized constructor - generate tuple tag; args are added by call builder
                // RGB(r, g, b) → {:rgb}
                return ETuple([makeAST(EAtom(atomName))]);
            } else {
                // Simple constructor - represent as one-element tuple for uniformity with patterns
                // TopicA → {:topic_a}
                return ETuple([makeAST(EAtom(atomName))]);
            }
        }
    }
    
    /**
     * Build static field access
     * 
     * WHY: Static fields can be enum abstracts that need atom conversion
     * WHAT: Handles static field access with special cases
     * HOW: Detects enum abstract fields and generates atoms when appropriate
     */
    static function buildStaticField(e: TypedExpr, classRef: Ref<ClassType>, cf: Ref<ClassField>, context: CompilationContext): Null<ElixirASTDef> {
        var className = classRef.get().name;
        var field = cf.get();
        var fieldName = field.name;
        
        #if debug_ast_builder
        // DISABLED: trace('[FieldAccessBuilder] Static field: ${className}.${fieldName}');
        #end
        
        // Check if this is an enum abstract field that should be an atom
        var isAtomField = false;
        var atomValue: String = null;
        
        // Check if the field's type is elixir.types.Atom
        switch (field.type) {
            case TAbstract(abstractRef, _):
                var abstractType = abstractRef.get();
                if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Atom") {
                    isAtomField = true;
                }
            case _:
        }
        
        // Check if this is an enum abstract field
        if (!isAtomField) {
            var classType = classRef.get();
            switch (classType.kind) {
                case KAbstractImpl(abstractRef):
                    var abstractType = abstractRef.get();
                    
                    // Check if the abstract type is Atom
                    switch (abstractType.type) {
                        case TAbstract(atomRef, _):
                            var atomType = atomRef.get();
                            if (atomType.pack.join(".") == "elixir.types" && atomType.name == "Atom") {
                                isAtomField = true;
                                
                                // Try to get the constant value
                                var fieldExpr = field.expr();
                                if (fieldExpr != null) {
                                    switch (fieldExpr.expr) {
                                        case TConst(TString(s)):
                                            atomValue = s;
                                        case TCast(castExpr, _):
                                            switch(castExpr.expr) {
                                                case TConst(TString(s)):
                                                    atomValue = s;
                                                default:
                                            }
                                        default:
                                    }
                                }
                            }
                        default:
                    }
                default:
            }
        }
        
        if (isAtomField && atomValue != null) {
            #if debug_ast_builder
            // DISABLED: trace('[FieldAccessBuilder] Generating atom: :${atomValue}');
            #end
            return EAtom(atomValue);
        }

	        // Build the object expression first
	        var objAST = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
        } else {
            null;
	        }

	        // Static variables compile as 0-arity functions in Elixir and must be invoked
	        // with parentheses to avoid ambiguity (`Module.field` parses as a 0-arity call).
	        //
	        // This also enables the compiler to back mutable statics with a store.
	        if (field.kind.match(FVar(_, _))) {
	            var moduleExpr = (objAST != null)
	                ? objAST
	                : makeAST(EVar(ModuleBuilder.extractModuleName(classRef.get())));
	            return ERemoteCall(moduleExpr, NameUtils.toSnakeCase(fieldName), []);
	        }

	        // Static method reference (closure): emit a function capture.
        //
        // WHY:
        // - Elixir requires capture syntax when passing a function value, e.g. `&Mod.fun/1`.
        // - A bare `Mod.fun` in expression position is parsed as a 0-arity call (`Mod.fun()`),
        //   which is incorrect for higher-arity callbacks like Enum.map/2.
        //
        // HOW:
        // - When the static field is a method and we're compiling a TField (not a TCall),
        //   produce `ECapture(EField(Mod, fun), arity)` so the printer outputs `&Mod.fun/arity`.
        switch (field.kind) {
            case FMethod(_):
                var arity = switch (field.type) {
                    case TFun(args, _): args.length;
                    default: 0;
                };
                var funName = NameUtils.toSafeElixirFunctionName(fieldName);
                // If referencing a method on the current module, prefer a local capture so
                // private functions (defp) remain callable (remote capture requires def).
                var isSameClass = false;
                if (context != null && context.currentClass != null) {
                    var cur = context.currentClass;
                    var ref = classRef.get();
                    isSameClass = (ref != null && cur != null && ref.name == cur.name && ref.pack.join(".") == cur.pack.join("."));
                }
                if (isSameClass) {
                    return ECapture(makeAST(EVar(funName)), arity);
                }

	                var moduleExpr = (objAST != null) ? objAST : makeAST(EVar(ModuleBuilder.extractModuleName(classRef.get())));
	                return ECapture(makeAST(EField(moduleExpr, funName)), arity);
	            default:
	        }
        
	        if (objAST == null) {
	            // Fallback to module reference
	            return ERemoteCall(
	                makeAST(EVar(ModuleBuilder.extractModuleName(classRef.get()))),
	                NameUtils.toSnakeCase(fieldName),
	                []
	            );
	        }
	        
	        // Field access on the compiled object
	        return EField(objAST, NameUtils.toSnakeCase(fieldName));
	    }
    
    /**
     * Build instance field access
     * 
     * WHY: Instance fields need proper object compilation
     * WHAT: Handles field access on instances and anonymous objects
     * HOW: Compiles object then accesses field
     */
    static function buildInstanceField(e: TypedExpr, cf: Ref<ClassField>, context: CompilationContext): Null<ElixirASTDef> {
        var field = cf.get();
        var fieldName = field.name;
        
        #if debug_ast_builder
        // DISABLED: trace('[FieldAccessBuilder] Instance field: ${fieldName}');
        #end
        
        // Compile the object expression
        var objAST = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
        } else {
            null;
        }

        if (objAST == null) {
            #if debug_ast_builder
            // DISABLED: trace('[FieldAccessBuilder] Failed to compile object for field access');
            #end
            return null;
        }

        var receiverType = haxe.macro.TypeTools.follow(e.t);
        var receiverInnerType = switch (receiverType) {
            case TAbstract(absRef, params):
                var abs = absRef.get();
                if (abs != null && abs.pack.length == 0 && abs.name == "Null" && params != null && params.length == 1) {
                    haxe.macro.TypeTools.follow(params[0]);
                } else {
                    receiverType;
                }
            default:
                receiverType;
        };

        // Special-case: String.length (Haxe) must lower to String.length/1 (Elixir).
        //
        // WHY:
        // - The printer has a generic `field == "length"` shortcut that prints `length(obj)`,
        //   which is correct for lists but wrong for strings.
        //
        // HOW:
        // - Use typed information from the receiver to detect String and emit an explicit
        //   remote call so the printer cannot misinterpret the access.
        if (fieldName == "length") {
            var isString = switch (receiverInnerType) {
                case TInst(_.get() => {name: "String"}, _): true;
                case TAbstract(_.get() => {name: "String"}, _): true;
                default: false;
            };
            if (isString) {
                return ERemoteCall(makeAST(EVar("String")), "length", [objAST]);
            }
        }

        // Generate field access (use snake_case for Elixir struct/map fields)
        var snakeField = NameUtils.toSnakeCase(fieldName);
        return EField(objAST, snakeField);
    }

    /**
     * Build dynamic field access
     * 
     * WHY: Dynamic field access needs Map.get pattern
     * WHAT: Transforms to Map.get call
     * HOW: Generates Map.get(object, field_name)
     */
    static function buildDynamicField(e: TypedExpr, fieldName: String, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        // DISABLED: trace('[FieldAccessBuilder] Dynamic field: ${fieldName}');
        #end

        // Compile the object expression
        var objAST = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
        } else {
            null;
        }
        
        if (objAST == null) {
            return null;
        }
        
        // Generate Map.get for dynamic field access
        return ERemoteCall(
            makeAST(EVar("Map")),
            "get",
            [objAST, makeAST(EAtom(fieldName))]
        );
    }
    
    /**
     * Build closure field access
     * 
     * WHY: Closures need special handling for method references
     * WHAT: Creates function reference to instance method
     * HOW: Generates & capture syntax
     */
    static function buildClosure(e: TypedExpr, closureType: Null<{c:Ref<ClassType>, params:Array<Type>}>, cf: Ref<ClassField>, context: CompilationContext): Null<ElixirASTDef> {
        // Handle null closure type (can happen for certain edge cases)
        if (closureType == null) {
            #if debug_ast_builder
            // DISABLED: trace('[FieldAccessBuilder] Closure with null type');
            #end
            return null;
        }
        
        var className = closureType.c.get().name;
        var methodName = cf.get().name;
        
        #if debug_ast_builder
        // DISABLED: trace('[FieldAccessBuilder] Closure: ${className}.${methodName}');
        #end
        
        // For closures, we need to generate a function reference
        // &Module.function/arity
        var arity = switch(cf.get().type) {
            case TFun(args, _): args.length;
            default: 0;
        };

        // Generate function capture: &Module.function/arity
        // Note: The capture operand must not include call parentheses.
        var funName = NameUtils.toSafeElixirFunctionName(methodName);
        // Prefer local capture for same-module refs so defp closures remain valid.
        var isSameClass = false;
        if (context != null && context.currentClass != null) {
            var cur = context.currentClass;
            var ref = closureType.c.get();
            isSameClass = (ref != null && cur != null && ref.name == cur.name && ref.pack.join(".") == cur.pack.join("."));
        }
        if (isSameClass) {
            return ECapture(makeAST(EVar(funName)), arity);
        }
        var functionRef = EField(makeAST(EVar(className)), funName);
        return ECapture(makeAST(functionRef), arity);
    }
    
    /**
     * Extract field name from FieldAccess
     * 
     * WHY: Field names are needed for various transformations
     * WHAT: Extracts the actual field name from different access types
     * HOW: Pattern matches on FieldAccess variants
     */
    public static function extractFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                cf.get().name;
            case FDynamic(s):
                s;
            case FEnum(_, ef):
                ef.name;
        }
    }
}

#end
