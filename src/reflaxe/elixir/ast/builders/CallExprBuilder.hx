package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.CompilationContext;

/**
 * CallExprBuilder: Builds ElixirAST nodes for function and method calls
 *
 * WHY: Function calls are complex and varied - static calls, method calls,
 * constructor calls, special functions, etc. Extracting this logic from
 * ElixirASTBuilder creates a focused module for call handling.
 *
 * WHAT: Converts TCall nodes to appropriate ElixirAST call structures:
 * - Static function calls (Module.function)
 * - Instance method calls (object.method)
 * - Constructor calls (new Class())
 * - Special functions (__elixir__, __instanceof__, etc.)
 * - Enum constructor calls
 * - Abstract type method calls
 *
 * HOW: Analyzes the call target and arguments to determine the call type,
 * then generates the appropriate ElixirAST structure. Uses CompilationContext
 * for module tracking and behavior transformations.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles call expressions
 * - Extensibility: Easy to add new call patterns
 * - Testability: Call logic can be tested in isolation
 * - Maintainability: Complex call logic separated from other concerns
 *
 * @see ElixirASTBuilder for integration
 * @see CompilationContext for state management
 */
class CallExprBuilder {

    /**
     * Build a function call expression
     *
     * WHY: Function calls are the primary way to invoke behavior
     * WHAT: Converts TCall nodes to ElixirAST call structures
     * HOW: Determines call type and delegates to appropriate builder
     */
    public static function buildCall(e: TypedExpr, el: Array<TypedExpr>, context: CompilationContext, buildExpr: TypedExpr -> ElixirAST): ElixirAST {
        // Store the expression builder for use in helper functions
        exprBuilder = buildExpr;

        // Determine what kind of call this is
        var callType = analyzeCallType(e);

        return switch(callType) {
            case StaticCall(module, method):
                buildStaticCall(module, method, el, context);
            case InstanceCall(target, method):
                buildInstanceCall(target, method, el, context);
            case ConstructorCall(cls):
                buildConstructorCall(cls, el, context);
            case SpecialFunction(name):
                buildSpecialFunction(name, el, context);
            case EnumConstructor(enumType, field):
                buildEnumConstructor(enumType, field, el, context);
            case LocalFunction(name):
                buildLocalCall(name, el, context);
            case Unknown:
                buildGenericCall(e, el, context);
        }
    }

    /**
     * Analyze what type of call this is
     */
    static function analyzeCallType(e: TypedExpr): CallType {
        return switch(e.expr) {
            case TField(target, FStatic(cls, cf)):
                StaticCall(cls.get().name, cf.get().name);
            case TField(target, FInstance(_, _, cf)):
                InstanceCall(target, cf.get().name);
            case TField(target, FEnum(_, ef)):
                EnumConstructor(null, ef.name);
            case TConst(TThis):
                ConstructorCall(null); // Constructor delegation
            case TIdent(name) if (isSpecialFunction(name)):
                SpecialFunction(name);
            case TIdent(name):
                LocalFunction(name);
            case TLocal(v):
                LocalFunction(v.name);
            default:
                Unknown;
        }
    }

    /**
     * Build a static function call
     */
    static function buildStaticCall(module: String, method: String, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        // Convert module and method names to Elixir conventions
        var elixirModule = toElixirModuleName(module);
        var elixirMethod = toElixirFunctionName(method);

        // Build argument ASTs
        var argASTs = [for (arg in args) buildArgument(arg, context)];

        // Check if this is a same-module call
        if (context.currentModule != null && module == context.currentModule) {
            // Same module - just use function name
            return makeCall(EVar(elixirMethod), argASTs);
        } else {
            // Cross-module - use Module.function
            return makeCall(EField(EVar(elixirModule), elixirMethod), argASTs);
        }
    }

    /**
     * Build an instance method call
     */
    static function buildInstanceCall(target: TypedExpr, method: String, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        // For Elixir, instance methods become module functions with the instance as first arg
        var targetAST = buildExpression(target, context);
        var elixirMethod = toElixirFunctionName(method);
        var argASTs = [for (arg in args) buildArgument(arg, context)];

        // Prepend the target as the first argument
        argASTs.unshift(targetAST);

        // Call as Module.function(instance, ...args)
        var moduleName = getModuleForType(target.t);
        if (moduleName != null) {
            return makeCall(EField(EVar(moduleName), elixirMethod), argASTs);
        } else {
            // Fallback to local function call
            return makeCall(EVar(elixirMethod), argASTs);
        }
    }

    /**
     * Build a constructor call
     */
    static function buildConstructorCall(cls: ClassType, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        // In Elixir, constructors become Module.new() calls
        if (cls != null) {
            var moduleName = toElixirModuleName(cls.name);
            var argASTs = [for (arg in args) buildArgument(arg, context)];
            return makeCall(EField(EVar(moduleName), "new"), argASTs);
        } else {
            // Constructor delegation - this() call
            var argASTs = [for (arg in args) buildArgument(arg, context)];
            return makeCall(EVar("new"), argASTs);
        }
    }

    /**
     * Build a special function call
     */
    static function buildSpecialFunction(name: String, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        return switch(name) {
            case "__elixir__":
                buildElixirInjection(args, context);
            case "__instanceof__":
                buildInstanceOf(args, context);
            case "__typeof__":
                buildTypeOf(args, context);
            default:
                // Unknown special function - treat as regular call
                var argASTs = [for (arg in args) buildArgument(arg, context)];
                makeCall(EVar(name), argASTs);
        }
    }

    /**
     * Build an __elixir__ injection call
     */
    static function buildElixirInjection(args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        if (args.length == 0) {
            return makeAST(ENil);
        }

        // First argument should be the Elixir code string
        var codeExpr = args[0];
        var code = extractStringConstant(codeExpr);

        if (code == null) {
            throw "First argument to __elixir__ must be a constant string";
        }

        // Build substitution arguments
        var substitutions = [];
        for (i in 1...args.length) {
            substitutions.push(buildArgument(args[i], context));
        }

        // Return raw Elixir code with substitutions
        return makeAST(ERaw(code, substitutions));
    }

    /**
     * Build an enum constructor call
     */
    static function buildEnumConstructor(enumType: EnumType, field: String, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        // Enum constructors become tuples in Elixir
        var atom = toElixirAtom(field);
        var elements = [makeAST(EAtom(atom))];

        // Add constructor arguments
        for (arg in args) {
            elements.push(buildArgument(arg, context));
        }

        return makeAST(ETuple(elements));
    }

    /**
     * Build a local function call
     */
    static function buildLocalCall(name: String, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        var elixirName = toElixirFunctionName(name);
        var argASTs = [for (arg in args) buildArgument(arg, context)];
        return makeCall(EVar(elixirName), argASTs);
    }

    /**
     * Build a generic call (fallback)
     */
    static function buildGenericCall(e: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): ElixirAST {
        var targetAST = buildExpression(e, context);
        var argASTs = [for (arg in args) buildArgument(arg, context)];
        return makeCall(targetAST, argASTs);
    }

    // Helper functions
    static var exprBuilder: TypedExpr -> ElixirAST;

    static function buildArgument(arg: TypedExpr, context: CompilationContext): ElixirAST {
        // Use the stored expression builder callback
        return exprBuilder(arg);
    }

    static function buildExpression(expr: TypedExpr, context: CompilationContext): ElixirAST {
        // Use the stored expression builder callback
        return exprBuilder(expr);
    }

    static function makeCall(target: ElixirAST, args: Array<ElixirAST>): ElixirAST {
        return makeAST(ECall(target, args));
    }

    static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }

    static function isSpecialFunction(name: String): Bool {
        return switch(name) {
            case "__elixir__", "__instanceof__", "__typeof__": true;
            default: false;
        }
    }

    static function extractStringConstant(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TConst(TString(s)): s;
            default: null;
        }
    }

    static function getModuleForType(t: Type): Null<String> {
        // Simplified - would need full type analysis
        return switch(t) {
            case TInst(cls, _): toElixirModuleName(cls.get().name);
            default: null;
        }
    }

    static function toElixirModuleName(name: String): String {
        // Convert to Elixir module naming convention
        return name;
    }

    static function toElixirFunctionName(name: String): String {
        // Convert camelCase to snake_case
        return toSnakeCase(name);
    }

    static function toElixirAtom(name: String): String {
        // Convert to snake_case atom
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
}

/**
 * Type of call being made
 */
enum CallType {
    StaticCall(module: String, method: String);
    InstanceCall(target: TypedExpr, method: String);
    ConstructorCall(cls: ClassType);
    SpecialFunction(name: String);
    EnumConstructor(enumType: EnumType, field: String);
    LocalFunction(name: String);
    Unknown;
}

#end