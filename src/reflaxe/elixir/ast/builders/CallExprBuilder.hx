package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.helpers.PatternDetector;
import reflaxe.elixir.ast.builders.VariableBuilder;
import reflaxe.elixir.ast.naming.ElixirNaming;

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

        // CRITICAL: Check for __elixir__() injection FIRST, before any other processing
        // This ensures code injection works regardless of other transformations
        if (context.compiler.options.targetCodeInjectionName != null && e != null && args.length > 0) {
            var isInjectionCall = switch(e.expr) {
                case TIdent(id): id == context.compiler.options.targetCodeInjectionName;
                case TField(_, fa):
                    switch(fa) {
                        case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                            cf.get().name == context.compiler.options.targetCodeInjectionName;
                        case FEnum(_, ef):
                            ef.name == context.compiler.options.targetCodeInjectionName;
                        case FDynamic(s):
                            s == context.compiler.options.targetCodeInjectionName;
                    }
                case TLocal(v): v.name == context.compiler.options.targetCodeInjectionName;
                case _: false;
            };

            if (isInjectionCall) {
                // Extract the injection string from first argument
                final injectionString: String = switch(args[0].expr) {
                    case TConst(TString(s)): s;
                    case _: "";
                };

                if (injectionString != "") {
                    #if debug_ast_builder
                    trace('[CallExpr] ✓ Detected __elixir__() injection: ${injectionString.substr(0, 50)}...');
                    #end

                    // SPECIAL-CASE: Ecto.Query.where injection → build AST so downstream passes can rewrite
                    if (injectionString.indexOf("Ecto.Query.where") != -1 && injectionString.indexOf("[t]") != -1 && args.length >= 3) {
                        var rx = ~/\[t\]\s*,\s*t\.([a-zA-Z0-9_]+)\s*(==|!=|<=|>=|<|>)\s*\^\(/;
                        if (rx.match(injectionString)) {
                            var fieldName = rx.matched(1);
                            var opStr = rx.matched(2);
                            var queryAst = buildExpression(args[1]);
                            var rhsAst = buildExpression(args[2]);
                            var binding = makeAST(EList([makeAST(EVar("t"))]));
                            var rhsStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(rhsAst);
                            var condition = makeAST(ERaw('t.' + fieldName + ' ' + opStr + ' ^(' + rhsStr + ')'));
                            return ERemoteCall(makeAST(EVar("Ecto.Query")), "where", [queryAst, binding, condition]);
                        }
                    }

                    // SPECIAL-CASE: Ecto.Query.order_by injection → build AST
                    if (injectionString.indexOf("Ecto.Query.order_by") != -1 && injectionString.indexOf("[t]") != -1 && args.length >= 3) {
                        // Extract order-by field(s) in simple form t.field or [desc: t.field]
                        var queryAst = buildExpression(args[1]);
                        var orderArgAst = buildExpression(args[2]);
                        var binding = makeAST(EList([makeAST(EVar("t"))]));
                        // Print order arg as raw to preserve ^ pinning or keyword list
                        var orderStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(orderArgAst);
                        var orderRaw = makeAST(ERaw(orderStr));
                        return ERemoteCall(makeAST(EVar("Ecto.Query")), "order_by", [queryAst, binding, orderRaw]);
                    }

                    // SPECIAL-CASE: Ecto.Query.preload injection → build AST
                    if (injectionString.indexOf("Ecto.Query.preload") != -1 && args.length >= 3) {
                        var queryAst = buildExpression(args[1]);
                        var preloadAst = buildExpression(args[2]);
                        // Preload does not require [t] binding; it accepts query and assoc list
                        return ERemoteCall(makeAST(EVar("Ecto.Query")), "preload", [queryAst, preloadAst]);
                    }

                    // SPECIAL-CASE: Ecto.Changeset.validate_required injection → build ERemoteCall
                    if (injectionString.indexOf("Ecto.Changeset.validate_required") != -1 && args.length >= 3) {
                        var thisAst = buildExpression(args[1]);
                        var fieldsAst = buildExpression(args[2]);
                        // Keep Enum.map(fields, &String.to_atom/1) as ERaw
                        var fieldsStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(fieldsAst);
                        var mappedFields = makeAST(ERaw('Enum.map(' + fieldsStr + ', &String.to_atom/1)'));
                        return ERemoteCall(makeAST(EVar("Ecto.Changeset")), "validate_required", [thisAst, mappedFields]);
                    }

                    // SPECIAL-CASE: Ecto.Changeset.validate_length injection → build ERemoteCall
                    if (injectionString.indexOf("Ecto.Changeset.validate_length") != -1 && args.length >= 3) {
                        var thisAst = buildExpression(args[1]);
                        var fieldAst = buildExpression(args[2]);
                        var atomField = makeAST(ERemoteCall(makeAST(EVar("String")), "to_atom", [fieldAst]));

                        // Detect which options are present and their order
                        var keys: Array<String> = [];
                        if (injectionString.indexOf("min:") != -1) keys.push("min");
                        if (injectionString.indexOf("max:") != -1) keys.push("max");
                        if (injectionString.indexOf("is:") != -1) keys.push("is");

                        var optIndex = 3;
                        var pairs: Array<reflaxe.elixir.ast.ElixirAST.EKeywordPair> = [];
                        for (k in keys) {
                            if (optIndex < args.length) {
                                var valAst = buildExpression(args[optIndex]);
                                pairs.push({key: k, value: valAst});
                                optIndex++;
                            }
                        }
                        var optionsAst = makeAST(EKeywordList(pairs));
                        return ERemoteCall(makeAST(EVar("Ecto.Changeset")), "validate_length", [thisAst, atomField, optionsAst]);
                    }

                    // Process parameter substitution with proper string interpolation handling
                    var finalCode = "";
                    var insideString = false;
                    var i = 0;

                    // Process character by character to detect quote state
                    while (i < injectionString.length) {
                        var char = injectionString.charAt(i);

                        // Track string state
                        if (char == '"' && (i == 0 || injectionString.charAt(i-1) != '\\')) {
                            insideString = !insideString;
                            finalCode += char;
                            i++;
                            continue;
                        }

                        // Check for {N} placeholder
                        if (char == '{' && i + 1 < injectionString.length) {
                            var j = i + 1;
                            var numStr = "";

                            // Collect digits
                            while (j < injectionString.length && injectionString.charAt(j) >= '0' && injectionString.charAt(j) <= '9') {
                                numStr += injectionString.charAt(j);
                                j++;
                            }

                            // Check if we found a valid placeholder like {0}, {1}, etc.
                            if (numStr != "" && j < injectionString.length && injectionString.charAt(j) == '}') {
                                final num = Std.parseInt(numStr);
                                if (num != null && num + 1 < args.length) {
                                    // Compile the argument
                                    var argAst = buildExpression(args[num + 1]);
                                    var argStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(argAst);

                                    if (insideString) {
                                        // Inside string: wrap in #{...} for interpolation
                                        finalCode += '#{$argStr}';
                                    } else {
                                        // Outside string: direct substitution
                                        finalCode += argStr;
                                    }

                                    // Skip past the placeholder
                                    i = j + 1;
                                    continue;
                                }
                            }
                        }

                        // Regular character - just append
                        finalCode += char;
                        i++;
                    }

                    #if debug_ast_builder
                    trace('[CallExpr] Generated injection code: $finalCode');
                    #end

                    // Return raw Elixir code directly
                    return ERaw(finalCode);
                }
            }
        }

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

                        // CRITICAL FIX: Convert method name to snake_case for Elixir function calls
                        // Function definitions use snake_case (parse_action), so calls must match
                        var elixirMethodName = ElixirNaming.toVarName(methodName);

                        // IDIOMATIC FIX: Within the same module, use unqualified function calls
                        // Elixir allows calling module functions directly when within that module
                        // Main.test_end() → test_end() for better idiomatic code
                        var currentClass = context.getCurrentClass();
                        var isSameModule = currentClass != null && currentClass.name == className;

                        if (isSameModule) {
                            // Same module - use direct function call
                            return ECall(null, elixirMethodName, argASTs);
                        } else {
                            // Different module - use qualified call
                            return ERemoteCall(makeAST(EVar(className)), elixirMethodName, argASTs);
                        }
                        
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
                // CRITICAL FIX: Must resolve variable name to check tempVarRenameMap
                // This ensures lambda function parameters use their snake_case names
                // (e.g., topicConverter -> topic_converter)
                var resolvedName = VariableBuilder.resolveVariableName(v, context);
                return ECall(makeAST(EVar(resolvedName)), "", argASTs);
                
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
                        // Std.string(value) → inspect(value)
                        // WHY: inspect/1 provides complete string representation for all Elixir types
                        // WHAT: Converts lists, maps, tuples, structs correctly (unlike to_string/1)
                        // HOW: Direct function call without module prefix (target=null, funcName="inspect")
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            // Use null target with funcName to generate plain function call
                            return ECall(null, "inspect", [value]);
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
                    // Phoenix.PubSub.subscribe/2 and unsubscribe/1 DO NOT take self()
                    var moduleRef = makeAST(EVar(className));
                    var argASTs = [for (arg in args) buildExpression(arg)];
                    return ERemoteCall(moduleRef, methodName, argASTs);

                case "broadcast", "broadcast_from":
                    // broadcast_from/3 takes a process (often self()) as first arg
                    // but we only add self() when the source explicitly provides it.
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

                    var selfCall = makeAST(ECall(null, "self", []));
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
