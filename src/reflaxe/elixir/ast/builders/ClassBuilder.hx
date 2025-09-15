package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.CompilationContext;

/**
 * ClassBuilder: Builds ElixirAST nodes for class and struct compilation
 *
 * WHY: Classes in Haxe need transformation to Elixir modules and structs.
 * Elixir doesn't have traditional OOP classes - instead it uses modules
 * with functions and structs for data. This module handles the complex
 * transformation from OOP patterns to functional Elixir patterns.
 *
 * WHAT: Converts class nodes to Elixir constructs:
 * - Class definitions → modules with structs
 * - Instance fields → struct fields
 * - Methods → module functions with first param as struct
 * - Static methods → module functions
 * - Constructors → new/init functions
 * - Inheritance → protocol/behavior patterns
 * - Interfaces → Elixir protocols
 *
 * HOW: Analyzes class metadata and structure to generate appropriate
 * Elixir modules. Simple data classes become structs, classes with
 * methods become modules with functions that take the struct as first
 * parameter, implementing the "self" pattern through parameter passing.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles class/struct transformation
 * - Metadata-Driven: Uses annotations to guide generation
 * - Protocol Support: Maps interfaces to Elixir protocols
 * - Clean Separation: Instance vs static clearly separated
 * - Idiomatic Output: Generates functional Elixir patterns
 *
 * EDGE CASES:
 * - Abstract classes (become protocols)
 * - Multiple inheritance (not supported directly)
 * - Private/protected visibility (module scoping)
 * - Generic classes (type parameters)
 * - Nested classes (flattened to modules)
 *
 * @see ElixirASTBuilder for integration
 * @see CompilationContext for class metadata storage
 */
class ClassBuilder {

    /**
     * Build a complete class definition
     *
     * WHY: Classes are the primary organizational unit in OOP
     * WHAT: Converts class to module with struct and functions
     * HOW: Analyzes class structure and generates Elixir module
     *
     * @param classType The class type information
     * @param fields Array of class fields (vars and functions)
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildClass(
        classType: ClassType,
        fields: Array<ClassField>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var moduleName = getModuleName(classType, context);
        var structFields = [];
        var functions = [];

        // Separate fields into struct fields and functions
        for (field in fields) {
            switch(field.kind) {
                case FVar(read, write):
                    if (!field.isStatic) {
                        structFields.push(buildStructField(field, context));
                    }
                case FMethod(_):
                    functions.push(buildMethod(field, classType, context));
            }
        }

        // Build struct definition if there are instance fields
        var structDef = structFields.length > 0 ?
            buildStructDefinition(structFields, context) : null;

        // Build constructor
        var constructor = buildConstructor(classType, structFields, context);
        if (constructor != null) {
            functions.insert(0, constructor);
        }

        // Generate module
        return makeAST(EModule(
            moduleName,
            structDef,
            functions
        ));
    }

    /**
     * Build an interface definition
     *
     * WHY: Interfaces define contracts in OOP
     * WHAT: Converts interface to Elixir protocol
     * HOW: Maps interface methods to protocol functions
     *
     * @param classType The interface type
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildInterface(
        classType: ClassType,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var protocolName = getModuleName(classType, context);
        var functions = [];

        for (field in classType.fields.get()) {
            if (field.kind.match(FMethod(_))) {
                functions.push(buildProtocolFunction(field, context));
            }
        }

        return makeAST(EProtocol(protocolName, functions));
    }

    /**
     * Build a class constructor
     *
     * WHY: Objects need initialization
     * WHAT: Converts constructor to new/init functions
     * HOW: Creates struct initialization with defaults
     */
    static function buildConstructor(
        classType: ClassType,
        structFields: Array<EStructField>,
        context: CompilationContext
    ): Null<ElixirAST> {
        // Check for explicit constructor
        var constructor = classType.constructor;
        if (constructor != null) {
            return buildExplicitConstructor(constructor.get(), classType, context);
        }

        // Generate default constructor
        return buildDefaultConstructor(structFields, context);
    }

    /**
     * Build a class method
     *
     * WHY: Methods define behavior on objects
     * WHAT: Converts method to module function
     * HOW: Adds struct as first parameter for instance methods
     */
    static function buildMethod(
        field: ClassField,
        classType: ClassType,
        context: CompilationContext
    ): ElixirAST {
        var name = toElixirFunctionName(field.name);
        var isStatic = field.isStatic;

        // Get method expression if available
        var methodExpr = field.expr();
        if (methodExpr == null) {
            // Abstract method or extern
            return makeAST(EComment('Abstract method: ${field.name}'));
        }

        // Build function with appropriate parameters
        if (isStatic) {
            return buildStaticMethod(name, methodExpr, context);
        } else {
            return buildInstanceMethod(name, methodExpr, classType, context);
        }
    }

    /**
     * Build an instance method with self parameter
     *
     * WHY: Instance methods need access to object state
     * WHAT: Adds struct as first parameter
     * HOW: Modifies function signature to include self
     */
    static function buildInstanceMethod(
        name: String,
        expr: TypedExpr,
        classType: ClassType,
        context: CompilationContext
    ): ElixirAST {
        // Extract function body and parameters
        var params = extractMethodParameters(expr);
        var body = extractMethodBody(expr);

        // Add self as first parameter
        var selfParam = makeAST(PVar("self"));
        params.insert(0, selfParam);

        // Transform body with self context
        context.currentReceiverParamName = "self";
        var bodyAST = exprBuilder(body);
        context.currentReceiverParamName = null;

        return makeAST(EFunction(
            name,
            params,
            bodyAST
        ));
    }

    /**
     * Build a static method
     *
     * WHY: Static methods don't need object instance
     * WHAT: Converts to regular module function
     * HOW: Direct function generation without self
     */
    static function buildStaticMethod(
        name: String,
        expr: TypedExpr,
        context: CompilationContext
    ): ElixirAST {
        var params = extractMethodParameters(expr);
        var body = extractMethodBody(expr);
        var bodyAST = exprBuilder(body);

        return makeAST(EFunction(
            name,
            params,
            bodyAST
        ));
    }

    /**
     * Build struct field definition
     *
     * WHY: Structs need field definitions
     * WHAT: Converts class field to struct field
     * HOW: Maps type and default value
     */
    static function buildStructField(
        field: ClassField,
        context: CompilationContext
    ): EStructField {
        var fieldName = toElixirFieldName(field.name);
        var defaultValue = field.expr() != null ?
            exprBuilder(field.expr()) :
            makeAST(ENil);

        return {
            name: fieldName,
            defaultValue: defaultValue,
            type: mapFieldType(field.type, context)
        };
    }

    /**
     * Build struct definition
     *
     * WHY: Elixir uses structs for data
     * WHAT: Creates defstruct declaration
     * HOW: Lists fields with defaults
     */
    static function buildStructDefinition(
        fields: Array<EStructField>,
        context: CompilationContext
    ): ElixirAST {
        var fieldDefs = [];
        for (field in fields) {
            fieldDefs.push({
                key: makeAST(EAtom(field.name)),
                value: field.defaultValue
            });
        }
        return makeAST(EStruct(fieldDefs));
    }

    /**
     * Build protocol function declaration
     *
     * WHY: Protocols define contracts
     * WHAT: Creates protocol function spec
     * HOW: Extracts signature without implementation
     */
    static function buildProtocolFunction(
        field: ClassField,
        context: CompilationContext
    ): ElixirAST {
        var name = toElixirFunctionName(field.name);
        var type = field.type;

        // Extract parameter count from type
        var paramCount = getParameterCount(type);
        var params = [];
        for (i in 0...paramCount) {
            params.push(makeAST(PVar('arg$i')));
        }

        return makeAST(EProtocolFunction(
            name,
            params
        ));
    }

    // Helper functions
    static var exprBuilder: TypedExpr -> ElixirAST;

    static function getModuleName(classType: ClassType, context: CompilationContext): String {
        // Check for @:native metadata
        if (classType.meta.has(":native")) {
            var meta = classType.meta.extract(":native")[0];
            if (meta.params != null && meta.params.length > 0) {
                switch(meta.params[0].expr) {
                    case EConst(CString(name, _)): return name;
                    default:
                }
            }
        }

        // Use package and class name
        var parts = classType.pack.copy();
        parts.push(classType.name);
        return parts.join(".");
    }

    static function toElixirFunctionName(name: String): String {
        // Convert camelCase to snake_case
        return toSnakeCase(name);
    }

    static function toElixirFieldName(name: String): String {
        // Convert camelCase to snake_case
        return toSnakeCase(name);
    }

    static function toSnakeCase(name: String): String {
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != "_") {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }

    static function extractMethodParameters(expr: TypedExpr): Array<ElixirAST> {
        // Extract parameters from function expression
        return switch(expr.expr) {
            case TFunction(func):
                func.args.map(arg -> makeAST(PVar(toElixirFunctionName(arg.v.name))));
            default:
                [];
        };
    }

    static function extractMethodBody(expr: TypedExpr): TypedExpr {
        // Extract body from function expression
        return switch(expr.expr) {
            case TFunction(func): func.expr;
            default: expr;
        };
    }

    static function buildExplicitConstructor(
        constructor: ClassField,
        classType: ClassType,
        context: CompilationContext
    ): ElixirAST {
        var expr = constructor.expr();
        if (expr == null) return null;

        var params = extractMethodParameters(expr);
        var body = extractMethodBody(expr);

        // Transform constructor body to return struct
        var structName = "%__MODULE__{}";
        var initCode = exprBuilder(body);

        var constructorBody = makeAST(EBlock([
            initCode,
            makeAST(EVar(structName))
        ]));

        return makeAST(EFunction(
            "new",
            params,
            constructorBody
        ));
    }

    static function buildDefaultConstructor(
        fields: Array<EStructField>,
        context: CompilationContext
    ): ElixirAST {
        // Generate new/0 and new/1 functions
        var newBody = makeAST(EVar("%__MODULE__{}"));

        return makeAST(EFunction(
            "new",
            [],
            newBody
        ));
    }

    static function mapFieldType(type: Type, context: CompilationContext): Dynamic {
        // Map Haxe type to Elixir type spec
        return switch(type) {
            case TInst(t, _):
                switch(t.get().name) {
                    case "String": ETypeString;
                    case "Int": ETypeInteger;
                    case "Float": ETypeFloat;
                    case "Bool": ETypeBoolean;
                    default: ETypeAny;
                }
            default:
                ETypeAny;
        };
    }

    static function getParameterCount(type: Type): Int {
        return switch(type) {
            case TFun(args, _): args.length;
            default: 0;
        };
    }

    // AST construction helper
    static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }
}

#end