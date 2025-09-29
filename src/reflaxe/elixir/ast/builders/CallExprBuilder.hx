package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.helpers.PatternDetector;

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
                        
                        // Check for special Haxe standard library calls
                        var specialCall = handleSpecialCall(className, methodName, args, context);
                        if (specialCall != null) {
                            return specialCall;
                        }
                        
                        // Check for Phoenix-specific patterns
                        var phoenixCall = handlePhoenixCall(className, methodName, args, context);
                        if (phoenixCall != null) {
                            return phoenixCall;
                        }
                        
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
     * Handle special Haxe standard library calls
     * 
     * WHY: Haxe's Std and Type classes need special mapping to Elixir
     * WHAT: Transforms Std.is, Std.string, Type.typeof, etc. to idiomatic Elixir
     * HOW: Maps specific function patterns to Elixir equivalents
     * 
     * @param className The class name (e.g., "Std", "Type")
     * @param methodName The method name (e.g., "is", "string")
     * @param args The call arguments
     * @param context Build context
     * @return ElixirASTDef for the special call, or null if not special
     */
    static function handleSpecialCall(className: String, methodName: String, args: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_ast_builder
        trace('[CallExpr] Checking special call: ${className}.${methodName}');
        #end
        
        switch(className) {
            case "Std":
                switch(methodName) {
                    case "is":
                        // Std.is(value, Type) → is_type(value)
                        if (args.length == 2) {
                            var value = buildExpression(args[0]);
                            var typeExpr = args[1];
                            
                            // Determine the Elixir type check function
                            var typeCheck = switch(typeExpr.expr) {
                                case TTypeExpr(TClassDecl(classRef)):
                                    var typeName = classRef.get().name;
                                    switch(typeName) {
                                        case "String": "is_binary";
                                        case "Int": "is_integer";
                                        case "Float": "is_float";
                                        case "Bool": "is_boolean";
                                        case "Array": "is_list";
                                        case "Map": "is_map";
                                        default: null;
                                    }
                                default: null;
                            };
                            
                            if (typeCheck != null) {
                                return ECall(makeAST(EVar(typeCheck)), "", [value]);
                            }
                        }
                        
                    case "string":
                        // Std.string(value) → to_string(value) or interpolation
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            return ECall(makeAST(EVar("to_string")), "", [value]);
                        }
                        
                    case "parseInt":
                        // Std.parseInt(str) → String.to_integer(str)
                        if (args.length == 1) {
                            var str = buildExpression(args[0]);
                            return ERemoteCall(makeAST(EVar("String")), "to_integer", [str]);
                        }
                        
                    case "parseFloat":
                        // Std.parseFloat(str) → String.to_float(str)
                        if (args.length == 1) {
                            var str = buildExpression(args[0]);
                            return ERemoteCall(makeAST(EVar("String")), "to_float", [str]);
                        }
                        
                    case "int":
                        // Std.int(float) → trunc(float)
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            return ECall(makeAST(EVar("trunc")), "", [value]);
                        }
                        
                    case "random":
                        // Std.random(max) → :rand.uniform(max)
                        if (args.length == 1) {
                            var max = buildExpression(args[0]);
                            return ERemoteCall(makeAST(EAtom("rand")), "uniform", [max]);
                        }
                }
                
            case "Type":
                switch(methodName) {
                    case "typeof":
                        // Type.typeof(value) → typeof implementation
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            // This would need a helper function in Elixir
                            return ECall(makeAST(EVar("typeof")), "", [value]);
                        }
                        
                    case "getClassName":
                        // Type.getClassName(c) → Module.split(c) |> List.last()
                        if (args.length == 1) {
                            var cls = buildExpression(args[0]);
                            var split = ERemoteCall(makeAST(EVar("Module")), "split", [cls]);
                            return ERemoteCall(makeAST(EVar("List")), "last", [makeAST(split)]);
                        }
                        
                    case "getEnumName":
                        // Type.getEnumName(e) → elem(e, 0) for tagged tuples
                        if (args.length == 1) {
                            var enumValue = buildExpression(args[0]);
                            return ECall(makeAST(EVar("elem")), "", [enumValue, makeAST(EInteger(0))]);
                        }
                }
                
            case "Reflect":
                switch(methodName) {
                    case "field":
                        // Reflect.field(obj, field) → Map.get(obj, field)
                        if (args.length == 2) {
                            var obj = buildExpression(args[0]);
                            var field = buildExpression(args[1]);
                            return ERemoteCall(makeAST(EVar("Map")), "get", [obj, field]);
                        }
                        
                    case "setField":
                        // Reflect.setField(obj, field, value) → Map.put(obj, field, value)
                        if (args.length == 3) {
                            var obj = buildExpression(args[0]);
                            var field = buildExpression(args[1]);
                            var value = buildExpression(args[2]);
                            return ERemoteCall(makeAST(EVar("Map")), "put", [obj, field, value]);
                        }
                        
                    case "hasField":
                        // Reflect.hasField(obj, field) → Map.has_key?(obj, field)
                        if (args.length == 2) {
                            var obj = buildExpression(args[0]);
                            var field = buildExpression(args[1]);
                            return ERemoteCall(makeAST(EVar("Map")), "has_key?", [obj, field]);
                        }
                }
        }
        
        // Not a special call
        return null;
    }
    
    /**
     * Handle Phoenix-specific call patterns
     * 
     * WHY: Phoenix framework calls often need special handling for self() injection
     * WHAT: Transforms PubSub, Presence, and other Phoenix patterns
     * HOW: Adds self() as first argument where needed, handles special patterns
     * 
     * @param className The class name (e.g., "TodoPubSub", "TodoPresence")
     * @param methodName The method name (e.g., "subscribe", "track")
     * @param args The call arguments
     * @param context Build context
     * @return ElixirASTDef for the Phoenix call, or null if not Phoenix-specific
     */
    static function handlePhoenixCall(className: String, methodName: String, args: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_ast_builder
        trace('[CallExpr] Checking Phoenix call: ${className}.${methodName}');
        #end
        
        // Check for PubSub patterns
        if (StringTools.endsWith(className, "PubSub")) {
            switch(methodName) {
                case "subscribe", "unsubscribe":
                    // PubSub.subscribe needs self() as first argument in LiveView context
                    var moduleRef = makeAST(EVar(className));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    
                    // Check if we're in a LiveView context (would need context metadata)
                    // For now, always inject self() for PubSub operations
                    var selfCall = makeAST(ECall(makeAST(EVar("self")), "", []));
                    argASTs.unshift(selfCall);
                    
                    return ERemoteCall(moduleRef, methodName, argASTs);
                    
                case "broadcast", "broadcast_from":
                    // These don't need self() injection
                    var moduleRef = makeAST(EVar(className));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Check for Presence patterns
        if (StringTools.endsWith(className, "Presence")) {
            switch(methodName) {
                case "track", "update", "untrack":
                    // Presence operations need self() as first argument
                    var moduleRef = makeAST(EVar(className));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    
                    var selfCall = makeAST(ECall(makeAST(EVar("self")), "", []));
                    argASTs.unshift(selfCall);
                    
                    return ERemoteCall(moduleRef, methodName, argASTs);
                    
                case "list":
                    // list() doesn't need self()
                    var moduleRef = makeAST(EVar(className));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Check for LiveView patterns
        if (className == "LiveView" || className == "Phoenix.LiveView") {
            switch(methodName) {
                case "assign", "assign_new", "clear_flash", "put_flash":
                    // These are typically called with socket as first arg
                    var moduleRef = makeAST(EVar("Phoenix.LiveView"));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    return ERemoteCall(moduleRef, methodName, argASTs);
                    
                case "push_event", "push_patch", "push_redirect":
                    // Event pushing functions
                    var moduleRef = makeAST(EVar("Phoenix.LiveView"));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Not a Phoenix-specific call
        return null;
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