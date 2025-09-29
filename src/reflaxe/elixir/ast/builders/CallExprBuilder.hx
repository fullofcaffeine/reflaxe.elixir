package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.PatternDetector;

/**
 * CallExprBuilder: Handles function/method call expression building
 * 
 * WHY: Separates call expression logic from ElixirASTBuilder
 * - Reduces main builder complexity (1100+ lines for TCall alone!)
 * - Centralizes call handling (methods, constructors, special functions)
 * - Handles Phoenix-specific patterns (Presence, PubSub, etc.)
 * 
 * WHAT: Builds ElixirAST nodes for various call types
 * - TCall: Function and method calls
 * - Enum constructor calls with idiomatic handling
 * - Special Haxe operations (Std.is, Type.typeof, etc.)
 * - Phoenix framework integrations
 * 
 * HOW: Analyzes call patterns and generates appropriate AST
 * - Detects enum constructors and generates tuples
 * - Handles special method transformations
 * - Manages function references and lambda calls
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only call expression logic
 * - Pattern Detection: Sophisticated call type recognition
 * - Framework Integration: Phoenix-specific optimizations
 * - Future-Ready: Easy to add new call patterns
 */
@:nullSafety(Off)
class CallExprBuilder {
    
    /**
     * Build a call expression
     * 
     * WHY: TCall represents all function/method calls in Haxe
     * WHAT: Generates appropriate ElixirAST for the call type
     * HOW: Pattern matches on call target to determine handling
     * 
     * @param e The call target expression
     * @param args The call arguments
     * @param context Build context with compilation state
     * @return ElixirASTDef for the call
     */
    public static function buildCall(e: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_ast_builder
        trace('[CallExpr] Processing TCall with ${args.length} args');
        if (e != null) {
            trace('[CallExpr] Call target: ${Type.enumConstructor(e.expr)}');
        }
        #end
        
        // Check if this is an enum constructor call first
        if (e != null && PatternDetector.isEnumConstructor(e)) {
            return buildEnumConstructor(e, args, context);
        }
        
        // For now, delegate back to the main builder for non-enum calls
        // This will be extracted incrementally
        if (e == null) {
            // Direct function call without target
            return ECall(null, "unknown_function", [for (arg in args) buildExpression(arg)]);
        }
        
        // Build the target and arguments
        var target = buildExpression(e);
        var argASTs = [for (arg in args) buildExpression(arg)];
        
        // Determine the call type
        switch(e.expr) {
            case TField(obj, fa):
                // Method or field call
                switch(fa) {
                    case FInstance(_, _, cf):
                        // Instance method call
                        var methodName = cf.get().name;
                        return ECall(buildExpression(obj), methodName, argASTs);
                        
                    case FStatic(classRef, cf):
                        // Static method call
                        var className = classRef.get().name;
                        var methodName = cf.get().name;
                        return ERemoteCall(makeAST(EVar(className)), methodName, argASTs);
                        
                    case FEnum(_, ef):
                        // This should have been caught by PatternDetector.isEnumConstructor
                        // But handle it as backup
                        return buildEnumConstructor(e, args, context);
                        
                    default:
                        // Other field access - generic call
                        return ECall(target, "", argASTs);
                }
                
            case TLocal(v):
                // Local variable call (lambda/function reference)
                return ECall(makeAST(EVar(v.name)), "", argASTs);
                
            default:
                // Generic call
                return ECall(target, "", argASTs);
        }
    }
    
    /**
     * Build enum constructor call as idiomatic tuple
     * 
     * WHY: Enum constructors in Elixir are represented as tagged tuples
     * WHAT: Converts Haxe enum constructor to {:tag, args...} pattern
     * HOW: Extracts tag name, converts to snake_case, builds tuple
     * 
     * @param e The enum constructor expression
     * @param args Constructor arguments
     * @param context Build context
     * @return ElixirASTDef for the enum tuple
     */
    static function buildEnumConstructor(e: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        // Extract the tag name from the enum constructor
        var tag = switch(e.expr) {
            case TField(_, FEnum(_, ef)): ef.name;
            case TField(_, FStatic(_, cf)): {
                var methodName = cf.get().name;
                methodName.charAt(0).toUpperCase() + methodName.substr(1);
            }
            default: "ModuleRef";
        };
        
        // Check if this enum should be idiomatic (snake_case tags)
        if (hasIdiomaticMetadata(e)) {
            tag = reflaxe.elixir.ast.NameUtils.toSnakeCase(tag);
            
            #if debug_ast_builder
            trace('[CallExpr] Building idiomatic enum tuple: ${tag} with ${args.length} args');
            #end
        }
        
        // Build arguments, checking for inline expansions
        var needsExtraction = false;
        var extractedAssignments: Array<ElixirAST> = [];
        var processedArgs: Array<ElixirAST> = [];
        
        for (i in 0...args.length) {
            var builtArg = buildExpression(args[i]);
            
            // Check if the built argument is an inline expansion block
            // This happens when optional parameters like substr(pos, ?len) are inlined
            var isInlineExpansion = switch(builtArg.def) {
                case EBlock(exprs) if (exprs.length == 2):
                    // Check for the pattern: [len = nil, if (len == nil) ...]
                    switch(exprs[0].def) {
                        case EMatch(PVar(_), {def: ENil}): true;
                        case EBinary(Match, _, {def: ENil}): true;
                        case EMatch(PVar(_), {def: EAtom(a)}) if (a == "nil"): true;
                        case EBinary(Match, _, {def: EAtom(a)}) if (a == "nil"): true;
                        default: false;
                    }
                default: false;
            };
            
            if (isInlineExpansion) {
                // Extract to a temporary variable before the tuple
                var tempVar = 'enum_arg_$i';
                var assignment = makeAST(EMatch(PVar(tempVar), builtArg));
                extractedAssignments.push(assignment);
                processedArgs.push(makeAST(EVar(tempVar)));
                needsExtraction = true;
            } else {
                processedArgs.push(builtArg);
            }
        }
        
        // Create the tuple AST definition
        var tupleDef = ETuple([makeAST(EAtom(tag))].concat(processedArgs));
        
        // If we extracted assignments, wrap in a block
        if (needsExtraction) {
            var blockExprs = extractedAssignments.copy();
            blockExprs.push(makeAST(tupleDef));
            tupleDef = EBlock(blockExprs);
        }
        
        return tupleDef;
    }
    
    /**
     * Check if an expression has idiomatic metadata
     * 
     * @param expr The expression to check
     * @return True if should generate idiomatic Elixir
     */
    static function hasIdiomaticMetadata(expr: TypedExpr): Bool {
        // Check for @:elixirIdiomatic or other metadata that indicates
        // this should generate idiomatic Elixir code
        switch(expr.expr) {
            case TField(_, FEnum(enumRef, _)):
                var enumType = enumRef.get();
                return enumType.meta.has("elixirIdiomatic");
            default:
                return false;
        }
    }
    
    /**
     * Helper to create AST nodes
     */
    static inline function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {def: def, metadata: {}, pos: pos};
    }
}

#end