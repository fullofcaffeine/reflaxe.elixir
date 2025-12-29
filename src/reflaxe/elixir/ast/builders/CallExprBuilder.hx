package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
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
        // DISABLED: trace('[CallExpr] Processing TCall with ${args.length} args');
        if (e != null) {
            // DISABLED: trace('[CallExpr] Call target: ${reflaxe.elixir.util.EnumReflection.enumConstructor(e.expr)}');
        }
        #end

        // Normalize common Array operations early (target-idiomatic)
        if (e != null) {
            switch (e.expr) {
                case TField(target, FInstance(_, _, cf)) if (cf.get().name == "concat" && args != null && args.length >= 1):
                    // Array.concat(other) → list ++ other (list concatenation)
                    var left = buildExpression(target);
                    var right = buildExpression(args[0]);
                    return EBinary(EBinaryOp.Concat, left, right);
                case TField(target2, FInstance(_, _, cf2)) if (cf2.get().name == "contains" && args != null && args.length == 1):
                    // Array.contains(x) → Enum.member?(list, x)
                    var listExpr = buildExpression(target2);
                    var needleExpr = buildExpression(args[0]);
                    return ERemoteCall(makeAST(EVar("Enum")), "member?", [listExpr, needleExpr]);
                default:
            }
        }

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
                    // DISABLED: trace('[CallExpr] ✓ Detected __elixir__() injection: ${injectionString.substr(0, 50)}...');
                    #end

                    // SPECIAL-CASE: Ecto.Query.where injection → build full AST (no ERaw)
                    if (injectionString.indexOf("Ecto.Query.where") != -1 && injectionString.indexOf("[t]") != -1 && args.length >= 3) {
                        // Match simple predicates of the form: [t], t.<field> <op> ^(...)
                        var rx = ~/\[t\]\s*,\s*t\.([a-zA-Z0-9_]+)\s*(==|!=|<=|>=|<|>)\s*\^\(/;
                        if (rx.match(injectionString)) {
                            var fieldName = rx.matched(1);
                            var opStr = rx.matched(2);
                            var queryAst = buildExpression(args[1]);
                            var rhsAst = buildExpression(args[2]);
                            var binding = makeAST(EList([makeAST(EVar("t"))]));

                            // Build condition: t.<field> <op> ^(rhs)
                            var left = makeAST(EField(makeAST(EVar("t")), fieldName));
                            // Preserve original formatting ^(rhs) by wrapping in parentheses
                            var right = makeAST(EPin(makeAST(EParen(rhsAst))));
                            var op: EBinaryOp = switch (opStr) {
                                case "==": EBinaryOp.Equal;
                                case "!=": EBinaryOp.NotEqual;
                                case "<=": EBinaryOp.LessEqual;
                                case ">=": EBinaryOp.GreaterEqual;
                                case "<": EBinaryOp.Less;
                                case ">": EBinaryOp.Greater;
                                default: EBinaryOp.Equal; // Fallback shouldn't happen given regex
                            };
                            var condition = makeAST(EBinary(op, left, right));
                            var whereCall = makeAST(ERemoteCall(makeAST(EVar("Ecto.Query")), "where", [queryAst, binding, condition]));
                            return whereCall.def;
                        }
                    }

                    // SPECIAL-CASE: Ecto.Query.order_by injection → build full AST (no ERaw)
                    if (injectionString.indexOf("Ecto.Query.order_by") != -1 && injectionString.indexOf("[t]") != -1 && args.length >= 3) {
                        // Handle common pattern: Ecto.Query.order_by({0}, [t], [asc: t.field]) or [desc: t.field]
                        var rxOrder = ~/order_by\(\{0\},\s*\[t\],\s*\[(asc|desc):\s*t\.([a-zA-Z0-9_]+)\]\)/;
                        var queryAst = buildExpression(args[1]);
                        var binding = makeAST(EList([makeAST(EVar("t"))]));

                        if (rxOrder.match(injectionString)) {
                            var dir = rxOrder.matched(1);
                            var fieldName2 = rxOrder.matched(2);
                            var kv: reflaxe.elixir.ast.ElixirAST.EKeywordPair = {
                                key: dir,
                                value: makeAST(EField(makeAST(EVar("t")), fieldName2))
                            };
                            var kw = makeAST(EKeywordList([kv]));
                            return ERemoteCall(makeAST(EVar("Ecto.Query")), "order_by", [queryAst, binding, kw]);
                        } else {
                            // Fallback: if injection didn't include direction, assume direct field arg passed as {1}
                            // Build [asc: t.<field>] if args[2] is a string atom or field name
                            var fieldAst = buildExpression(args[2]);
                            // Try to detect plain field name string to build t.field
                            var fieldNameMaybe: Null<String> = switch (args[2].expr) {
                                case TConst(TString(s)): s;
                                default: null;
                            };
                            var valueNode = fieldNameMaybe != null
                                ? makeAST(EField(makeAST(EVar("t")), fieldNameMaybe))
                                : fieldAst; // best effort
                            var kvAsc: reflaxe.elixir.ast.ElixirAST.EKeywordPair = { key: "asc", value: valueNode };
                            var kwAsc = makeAST(EKeywordList([kvAsc]));
                            return ERemoteCall(makeAST(EVar("Ecto.Query")), "order_by", [queryAst, binding, kwAsc]);
                        }
                    }

                    // SPECIAL-CASE: Ecto.Query.preload injection → build AST
                    if (injectionString.indexOf("Ecto.Query.preload") != -1 && args.length >= 3) {
                        var queryAst = buildExpression(args[1]);
                        var preloadAst = buildExpression(args[2]);
                        // Preload does not require [t] binding; it accepts query and assoc list
                        return ERemoteCall(makeAST(EVar("Ecto.Query")), "preload", [queryAst, preloadAst]);
                    }

                    // SPECIAL-CASE: Ecto.Query.from injection → build pure AST (no ERaw)
                    // Pattern used by TypedQuery.from: '(require Ecto.Query; Ecto.Query.from(t in {0}, []))'
                    if (injectionString.indexOf("Ecto.Query.from") != -1 && injectionString.indexOf(" in ") != -1 && args.length >= 2) {
                        // Args: [ codeString, schemaClass ]
                        // Build first argument as binary 't in <Schema>' with proper AST nodes
                        // Resolve schema module name robustly (prefer @:native on class)
                        var schemaModuleAst: reflaxe.elixir.ast.ElixirAST = null;
                        switch (args[1].expr) {
                            case TTypeExpr(TClassDecl(classRef)):
                                var cls = classRef.get();
                                var nativeName: Null<String> = null;
                                if (cls.meta.has(":native")) {
                                    var meta = cls.meta.extract(":native");
                                    if (meta != null && meta.length > 0 && meta[0].params != null && meta[0].params.length > 0) {
                                        switch (meta[0].params[0].expr) {
                                            case EConst(CString(s, _)): nativeName = s;
                                            default:
                                        }
                                    }
                                }
                                var moduleName = nativeName != null ? nativeName : cls.name;
                                schemaModuleAst = makeAST(EVar(moduleName));
                            default:
                                // Fallback: build expression normally (covers already-built module refs)
                                schemaModuleAst = buildExpression(args[1]);
                        }
                        var inExpr = makeAST(EBinary(In, makeAST(EVar("t")), schemaModuleAst));
                        var emptyOpts = makeAST(EList([]));
                        var fromCall = makeAST(ERemoteCall(makeAST(EVar("Ecto.Query")), "from", [inExpr, emptyOpts]));
                        return fromCall.def;
                    }

                    // SPECIAL-CASE: Ecto.Changeset.validate_required injection → build ERemoteCall (no ERaw)
                    // IMPORTANT: Only trigger for the simple, single-call template.
                    // Do not match multi-step pipelines (which should remain ERaw).
                    var trimmedInjection = StringTools.trim(injectionString);
                    if (args.length >= 3
                        && trimmedInjection.indexOf("|>") == -1
                        && StringTools.startsWith(trimmedInjection, "Ecto.Changeset.validate_required(")
                    ) {
                        var thisAst = buildExpression(args[1]);
                        var fieldsAst = buildExpression(args[2]);
                        // Build Enum.map(fields, &String.to_atom/1)
                        var capture = makeAST(ECapture(makeAST(EField(makeAST(EVar("String")), "to_atom")), 1));
                        var mappedFields = makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [fieldsAst, capture]));
                        return ERemoteCall(makeAST(EVar("Ecto.Changeset")), "validate_required", [thisAst, mappedFields]);
                    }

                    // SPECIAL-CASE: Ecto.Changeset.validate_length injection → build ERemoteCall
                    // IMPORTANT: Only trigger for the simple, single-call template.
                    if (args.length >= 3
                        && trimmedInjection.indexOf("|>") == -1
                        && StringTools.startsWith(trimmedInjection, "Ecto.Changeset.validate_length(")
                    ) {
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

                    // SPECIAL-CASE: Phoenix.Presence injections → build ERemoteCall to expose EVar usage
                    // Target module determination: inside presence modules, route to <App>Web.Presence
                    // otherwise keep Phoenix.Presence for external contexts.
                    // Resolve target presence module based on compilation context
                    var presenceTargetModule = "Phoenix.Presence";
                    if (context != null && (context.currentModuleHasPresence == true)) {
                        var appPrefix: Null<String> = null;
                        if (context.currentModule != null) {
                            var webIndex = context.currentModule.indexOf("Web");
                            if (webIndex > 0) appPrefix = context.currentModule.substring(0, webIndex);
                        }
                        if (appPrefix == null) {
                            try appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e) {}
                        }
                        if (appPrefix != null) presenceTargetModule = appPrefix + "Web.Presence";
                    }
                    if (injectionString.indexOf("Phoenix.Presence.track") != -1 && args.length >= 5) {
                        var socketAst = buildExpression(args[1]);
                        var topicAst = buildExpression(args[2]);
                        var keyAst = buildExpression(args[3]);
                        var metaAst = buildExpression(args[4]);
                        return ERemoteCall(makeAST(EVar(presenceTargetModule)), "track", [socketAst, topicAst, keyAst, metaAst]);
                    }
                    if (injectionString.indexOf("Phoenix.Presence.update") != -1 && args.length >= 5) {
                        var socketAst = buildExpression(args[1]);
                        var topicAst = buildExpression(args[2]);
                        var keyAst = buildExpression(args[3]);
                        var metaAst = buildExpression(args[4]);
                        return ERemoteCall(makeAST(EVar(presenceTargetModule)), "update", [socketAst, topicAst, keyAst, metaAst]);
                    }
                    if (injectionString.indexOf("Phoenix.Presence.untrack") != -1 && args.length >= 4) {
                        var socketAst = buildExpression(args[1]);
                        var topicAst = buildExpression(args[2]);
                        var keyAst = buildExpression(args[3]);
                        return ERemoteCall(makeAST(EVar(presenceTargetModule)), "untrack", [socketAst, topicAst, keyAst]);
                    }
                    if (injectionString.indexOf("Phoenix.Presence.list") != -1 && args.length >= 2) {
                        var topicAst = buildExpression(args[1]);
                        return ERemoteCall(makeAST(EVar(presenceTargetModule)), "list", [topicAst]);
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
                    // DISABLED: trace('[CallExpr] Generated injection code: $finalCode');
                    #end

                    // Return raw Elixir code directly
                    return ERaw(finalCode);
                }
            }
        }

        // Handle HXX.hxx(template) → ESigil("H", content)
        // This enables deterministic ~H generation even when HXX is a stub returning strings.
        if (e != null) {
            switch (e.expr) {
                case TField(target, fa):
                    switch (fa) {
                        case FStatic(classRef, cf):
                            var cls = classRef.get();
                            var methodName = cf.get().name;
                            if (cls.name == "HXX" && methodName == "hxx" && args.length >= 1) {
                                // Build inner argument AST
                                var innerAst = buildExpression(args[0]);
                                // Fast-path: if literal string already contains EEx/HEEx markers, emit ~H as-is
                                switch (innerAst.def) {
                                    case EString(s):
                                        if (s.indexOf("<%=") != -1 || s.indexOf("<% ") != -1 || s.indexOf("<%\n") != -1) {
                                            // Preserve existing EEx but still lower HXX <for> blocks
                                            var pre = reflaxe.elixir.ast.TemplateHelpers.rewriteForBlocks(s);
                                            return ESigil("H", pre, "");
                                        }
                                    default:
                                }
                                // General path: collect template content and normalize HXX control tags
                                var content = reflaxe.elixir.ast.TemplateHelpers.collectTemplateContent(innerAst);
                                content = reflaxe.elixir.ast.transformers.HeexControlTagTransforms.rewrite(content);
                                return ESigil("H", content, "");
                            }
                        default:
                    }
                default:
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

        // Build arguments with awareness of the callee's expected types.
        //
        // WHY:
        // - Some Elixir "compile-time marker" abstracts (notably `elixir.types.Atom`) need to
        //   affect printing even though they are represented as `String` at the Haxe level.
        // - Haxe does not always propagate abstract-expected types to literal constants in
        //   the argument expression tree, so relying solely on `arg.t` can emit `"count"`
        //   where `:count` is required (Phoenix assigns keys).
        //
        // HOW:
        // - When the callee type is TFun, peek the expected arg types and, for Atom-typed
        //   arguments, rewrite literal strings to atoms at the AST level.
        var expectedFunArgs: Null<Array<{name: String, opt: Bool, t: Type}>> = null;
        var expectedArgTypes: Null<Array<Type>> = null;
        switch (haxe.macro.TypeTools.follow(e.t)) {
            case TFun(fnArgs, _):
                expectedFunArgs = fnArgs;
                expectedArgTypes = [for (a in fnArgs) a.t];
            default:
        }

        inline function isAtomType(t: Null<Type>): Bool {
            if (t == null) return false;
            return switch (haxe.macro.TypeTools.follow(t)) {
                case TAbstract(ref, _):
                    var at = ref.get();
                    at.pack.join(".") == "elixir.types" && at.name == "Atom";
                default:
                    false;
            }
        }

        var argASTs: Array<ElixirAST> = [];
        for (i in 0...args.length) {
            var expected = (expectedArgTypes != null && i < expectedArgTypes.length) ? expectedArgTypes[i] : null;
            var builtArg = buildExpression(args[i]);
            if (isAtomType(expected)) {
                switch (builtArg.def) {
                    case EString(s):
                        builtArg = makeASTWithMeta(EAtom(s), builtArg.metadata, builtArg.pos);
                    default:
                }
            }
            argASTs.push(builtArg);
        }

        // Optional args: Haxe typed calls can omit trailing optional parameters.
        // Elixir requires exact arity, so pad omitted trailing optionals with `nil`.
        //
        // Example (Haxe):
        //   getString(pos, len) // where getString(pos, len, ?encoding)
        // Elixir (desired):
        //   get_string(struct, pos, len, nil)
        if (expectedFunArgs != null && args.length < expectedFunArgs.length) {
            for (i in args.length...expectedFunArgs.length) {
                if (expectedFunArgs[i].opt) {
                    argASTs.push(makeAST(ENil));
                }
            }
        }
        
        // Determine the call type
        switch(e.expr) {
            case TField(obj, fa):
                // Method or field call
                switch(fa) {
                    case FInstance(classRef, _, cf):
                        // Instance method call
                        var classType = classRef.get();
                        var className = classType.name;
                        var moduleName = ModuleBuilder.extractModuleName(classType);
                        var methodName = cf.get().name;

                        // ------------------------------------------------------------
                        // String instance methods (extern declarations in std/String.cross.hx)
                        //
                        // WHY:
                        // - Elixir has no `obj.method()` dispatch. Emitting ECall for String
                        //   methods prints invalid Elixir (`str.toLowerCase()`), or worse,
                        //   triggers Enum.* remaps in the printer (e.g., `split`/`join`).
                        //
                        // HOW:
                        // - Use typed info from the receiver to detect String and lower
                        //   to `String.*` / `Enum.*` calls with Haxe-compatible behavior.
                        // ------------------------------------------------------------
                        var isStringReceiver = switch (haxe.macro.TypeTools.follow(obj.t)) {
                            case TInst(_.get() => {name: "String"}, _): true;
                            case TAbstract(_.get() => {name: "String"}, _): true;
                            default: false;
                        };
                        if (isStringReceiver) {
                            var receiverAst = buildExpression(obj);
                            var lowered: Null<ElixirASTDef> = null;

                            inline function stringRemote(fnName: String, callArgs: Array<ElixirAST>): ElixirASTDef {
                                return ERemoteCall(makeAST(EVar("String")), fnName, callArgs);
                            }

                            switch (methodName) {
                                case "toString":
                                    lowered = receiverAst.def;

                                case "toLowerCase":
                                    lowered = stringRemote("downcase", [receiverAst]);

                                case "toUpperCase":
                                    lowered = stringRemote("upcase", [receiverAst]);

                                case "split" if (argASTs != null && argASTs.length == 1):
                                    var delim = argASTs[0];
                                    // Haxe: "".split("") -> ["a","b","c"] (no empties)
                                    // Elixir: String.split(str, "") includes empty segments unless we special-case.
                                    var cond = makeAST(EBinary(Equal, delim, makeAST(EString(""))));
                                    var graphemes = makeAST(stringRemote("graphemes", [receiverAst]));
                                    var splitCall = makeAST(stringRemote("split", [receiverAst, delim]));
                                    lowered = EIf(cond, graphemes, splitCall);

                                case "substr" if (argASTs != null && (argASTs.length == 1 || argASTs.length == 2)):
                                    var pos = argASTs[0];
                                    var lenOpt: Null<ElixirAST> = (argASTs.length == 2) ? argASTs[1] : null;
                                    var isOmitted = (lenOpt == null) || switch (lenOpt.def) { case ENil: true; default: false; };
                                    if (isOmitted) {
                                        // Elixir 1.18 warns on descending default step for negative indices in String.slice/2.
                                        // Use explicit positive step so String.slice treats -1 as "until end".
                                        var range = makeAST(ERange(pos, makeAST(EInteger(-1)), false, makeAST(EInteger(1))));
                                        lowered = stringRemote("slice", [receiverAst, range]);
                                    } else {
                                        lowered = stringRemote("slice", [receiverAst, pos, lenOpt]);
                                    }

                                case "substring" if (argASTs != null && (argASTs.length == 1 || argASTs.length == 2)):
                                    var startIdx = argASTs[0];
                                    var endOpt: Null<ElixirAST> = (argASTs.length == 2) ? argASTs[1] : null;
                                    var endOmitted = (endOpt == null) || switch (endOpt.def) { case ENil: true; default: false; };
                                    if (endOmitted) {
                                        // Elixir 1.18 warns on descending default step for negative indices in String.slice/2.
                                        // Use explicit positive step so String.slice treats -1 as "until end".
                                        var range = makeAST(ERange(startIdx, makeAST(EInteger(-1)), false, makeAST(EInteger(1))));
                                        lowered = stringRemote("slice", [receiverAst, range]);
                                    } else {
                                        var lenExpr = makeAST(EBinary(Subtract, endOpt, startIdx));
                                        lowered = stringRemote("slice", [receiverAst, startIdx, lenExpr]);
                                    }

                                case "charAt" if (argASTs != null && argASTs.length == 1):
                                    var idx = argASTs[0];
                                    var atCall = makeAST(stringRemote("at", [receiverAst, idx]));
                                    var fallback = makeAST(EString(""));
                                    var orElse = makeAST(EBinary(OrElse, atCall, fallback));
                                    // Preserve Haxe semantics for negative indices: return "".
                                    var isNegative = makeAST(EBinary(Less, idx, makeAST(EInteger(0))));
                                    lowered = EIf(isNegative, fallback, orElse);

                                case "charCodeAt" if (argASTs != null && argASTs.length == 1):
                                    var index = argASTs[0];
                                    // Enum.at(String.to_charlist(str), idx) returns nil when out-of-range.
                                    var charlist = makeAST(stringRemote("to_charlist", [receiverAst]));
                                    var enumAt = makeAST(ERemoteCall(makeAST(EVar("Enum")), "at", [charlist, index]));
                                    var isNegativeIndex = makeAST(EBinary(Less, index, makeAST(EInteger(0))));
                                    lowered = EIf(isNegativeIndex, makeAST(ENil), enumAt);

                                case "indexOf" if (argASTs != null && (argASTs.length == 1 || argASTs.length == 2)):
                                    var needle = argASTs[0];
                                    var startOpt: Null<ElixirAST> = (argASTs.length == 2) ? argASTs[1] : null;
                                    var startIsZero = (startOpt == null) || switch (startOpt.def) { case ENil: true; case EInteger(n) if (n == 0): true; default: false; };
                                    var subject = receiverAst;
                                    var offset: Null<ElixirAST> = null;
                                    if (!startIsZero && startOpt != null) {
                                        // Slice from start index and search within the slice, then add offset.
                                        var sliceRange = makeAST(ERange(startOpt, makeAST(EInteger(-1)), false, null));
                                        subject = makeAST(stringRemote("slice", [receiverAst, sliceRange]));
                                        offset = startOpt;
                                    }
                                    var matchCall = makeAST(ERemoteCall(makeAST(EAtom("binary")), "match", [subject, needle]));
                                    var clauses: Array<reflaxe.elixir.ast.ElixirAST.ECaseClause> = [
                                        { pattern: PTuple([PVar("pos"), PWildcard]), guard: null, body: makeAST(offset != null ? EBinary(Add, makeAST(EVar("pos")), offset) : EVar("pos")) },
                                        { pattern: PLiteral(makeAST(EAtom("nomatch"))), guard: null, body: makeAST(EInteger(-1)) }
                                    ];
                                    lowered = ECase(matchCall, clauses);

                                case "lastIndexOf" if (argASTs != null && (argASTs.length == 1 || argASTs.length == 2)):
                                    // Best-effort: mirror previous std/String.cross.hx behavior using split/join.
                                    var needle = argASTs[0];
                                    var startOpt: Null<ElixirAST> = (argASTs.length == 2) ? argASTs[1] : null;
                                    var startExpr = (startOpt == null || switch (startOpt.def) { case ENil: true; default: false; })
                                        ? makeAST(stringRemote("length", [receiverAst]))
                                        : startOpt;
                                    var sub = makeAST(stringRemote("slice", [receiverAst, makeAST(EInteger(0)), startExpr]));
                                    var parts = makeAST(stringRemote("split", [sub, needle]));
                                    // case parts do [..] when length(parts) > 1 -> String.length(Enum.join(Enum.slice(parts, 0..-2), needle)); _ -> -1 end
                                    var partsVar = makeAST(EVar("parts"));
                                    var condLen = makeAST(EBinary(Greater, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [partsVar])), makeAST(EInteger(1))));
                                    // Enum.slice/2 warns on descending default step for negative indices; force step 1.
                                    var sliceRange = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(-2)), false, makeAST(EInteger(1))));
                                    var sliced = makeAST(ERemoteCall(makeAST(EVar("Enum")), "slice", [partsVar, sliceRange]));
                                    var joined = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [sliced, needle]));
                                    var lenJoined = makeAST(stringRemote("length", [joined]));
                                    lowered = ECase(parts, [
                                        { pattern: PVar("parts"), guard: condLen, body: lenJoined },
                                        { pattern: PWildcard, guard: null, body: makeAST(EInteger(-1)) }
                                    ]);

                                default:
                            }

                            if (lowered != null) {
                                return lowered;
                            }
                        }

                        // Elixir values don't support method syntax; for certain extern-backed
                        // structs (e.g., NaiveDateTime), rewrite method-style calls to proper
                        // module calls.
                        //
                        // Example: d.to_iso8601() -> NaiveDateTime.to_iso8601(d)
                        if (methodName == "to_iso8601" && (args == null || args.length == 0)) {
                            var receiverAst = buildExpression(obj);
                            var moduleName: Null<String> = null;
                            var followed = haxe.macro.TypeTools.follow(obj.t);
                            switch (followed) {
                                case TInst(classRef, _):
                                    var ct = classRef.get();
                                    if (ct != null && ct.isExtern) {
                                        moduleName = ModuleBuilder.extractModuleName(ct);
                                    }
                                default:
                            }
                            if (moduleName != null && moduleName.length > 0) {
                                return ERemoteCall(makeAST(EVar(moduleName)), methodName, [receiverAst]);
                            }
                        }

                        // Array instance methods: arrays are represented as plain Elixir lists, not as a
                        // runtime `Array` module. Lower common ops directly to `Enum.*`/`++` so the
                        // generated code stays self-contained and idiomatic.
                        if (className == "Array" && (classType.pack == null || classType.pack.length == 0)) {
                            var receiverAst = buildExpression(obj);
                            var receiverLocal: Null<TVar> = switch (obj.expr) {
                                case TLocal(vLocal): vLocal;
                                default: null;
                            };
                            var receiverVarName: Null<String> = receiverLocal != null
                                ? VariableBuilder.resolveVariableName(receiverLocal, context)
                                : null;

                            function isFunctionParam(local: Null<TVar>): Bool {
                                if (local == null) return false;
                                return context.functionParameterIds.exists(Std.string(local.id));
                            }

                            function isCurrentClassInstanceField(varName: String): Bool {
                                if (varName == null || varName == "") return false;
                                var currentClass = context.getCurrentClass();
                                if (currentClass == null) return false;

                                // Only consider actual instance vars (FVar) and compare using Elixir snake_case.
                                for (field in currentClass.fields.get()) {
                                    switch (field.kind) {
                                        case FVar(_, _):
                                            var snakeFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                                            if (snakeFieldName == varName) {
                                                return true;
                                            }
                                        default:
                                    }
                                }
                                return false;
                            }

                            function structUpdateFieldAppend(fieldName: String, item: ElixirAST): ElixirASTDef {
                                var structVar = makeAST(EVar("struct"));
                                var newValue = makeAST(EBinary(Concat, makeAST(EField(structVar, fieldName)), makeAST(EList([item]))));
                                var updatedStruct = makeAST(EStructUpdate(structVar, [{ key: fieldName, value: newValue }]));
                                return EMatch(PVar("struct"), updatedStruct);
                            }

                            inline function listOf(single: ElixirAST): ElixirAST {
                                return makeAST(EList([single]));
                            }

                                switch (methodName) {
                                    case "copy":
                                        return receiverAst.def;

                                    case "map" if (argASTs != null && argASTs.length == 1):
                                        return ERemoteCall(makeAST(EVar("Enum")), "map", [receiverAst, argASTs[0]]);

                                    case "filter" if (argASTs != null && argASTs.length == 1):
                                        return ERemoteCall(makeAST(EVar("Enum")), "filter", [receiverAst, argASTs[0]]);

                                    case "join" if (argASTs != null && argASTs.length == 1):
                                        return ERemoteCall(makeAST(EVar("Enum")), "join", [receiverAst, argASTs[0]]);

                                    case "push" if (argASTs != null && argASTs.length == 1):
                                        // Haxe: mutates array in-place; Elixir: rebind to appended list.
                                        // Special-case: instance-field arrays in class method context should update the struct field.
                                        if (context.isInClassMethodContext
                                            && receiverVarName != null
                                            && !isFunctionParam(receiverLocal)
                                            && isCurrentClassInstanceField(receiverVarName)) {
                                            return structUpdateFieldAppend(receiverVarName, argASTs[0]);
                                        }

                                        var appended = makeAST(EBinary(Concat, receiverAst, listOf(argASTs[0])));
                                        if (receiverVarName != null) return EMatch(PVar(receiverVarName), appended);
                                        return appended.def;

                                    case "sort" if (argASTs != null && argASTs.length == 1):
                                        // Haxe comparator returns Int (-1/0/1); Enum.sort/2 expects boolean comparator.
                                        var cmp = argASTs[0];
                                        var aVar = makeAST(EVar("a"));
                                        var bVar = makeAST(EVar("b"));
                                        var cmpCall = makeAST(ECall(cmp, "", [aVar, bVar]));
                                        var cmpLessThanZero = makeAST(EBinary(Less, cmpCall, makeAST(EInteger(0))));
                                        var wrapper = makeAST(EFn([{
                                            args: [PVar("a"), PVar("b")],
                                            guard: null,
                                            body: cmpLessThanZero
                                        }]));
                                        var sortedCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "sort", [receiverAst, wrapper]));
                                        // Special-case: instance-field arrays in class method context should update the struct field.
                                        if (context.isInClassMethodContext
                                            && receiverVarName != null
                                            && !isFunctionParam(receiverLocal)
                                            && isCurrentClassInstanceField(receiverVarName)) {
                                            var structVar = makeAST(EVar("struct"));
                                            var fieldAst = makeAST(EField(structVar, receiverVarName));
                                            var sortedFieldCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "sort", [fieldAst, wrapper]));
                                            var updatedStruct = makeAST(EStructUpdate(
                                                structVar,
                                                [{ key: receiverVarName, value: sortedFieldCall }]
                                            ));
                                            return EMatch(PVar("struct"), updatedStruct);
                                        }

                                        if (receiverVarName != null) return EMatch(PVar(receiverVarName), sortedCall);
                                        return sortedCall.def;

                                default:
                            }
                        }

                        // Respect `@:native` on instance fields when present.
                        // See FStatic handling for the rationale.
                        var nativeFieldName = extractNativeModuleName(cf.get().meta);
                        var resolvedMethodName: Null<String> = null;
                        if (nativeFieldName != null) {
                            var lastDot = nativeFieldName.lastIndexOf(".");
                            if (lastDot != -1) {
                                moduleName = nativeFieldName.substr(0, lastDot);
                                resolvedMethodName = nativeFieldName.substr(lastDot + 1);
                            } else {
                                resolvedMethodName = nativeFieldName;
                            }
                        }

                        var elixirMethodName = resolvedMethodName != null
                            ? resolvedMethodName
                            : ElixirNaming.toVarName(methodName);

                        // Instance methods compile to module functions with the instance
                        // passed as the first argument: Module.method(struct, ...).
                        var receiverAst = buildExpression(obj);
                        var callArgs = [receiverAst].concat(argASTs);

                        var currentClass = context.getCurrentClass();
                        var isSameModule = currentClass != null && currentClass.name == className;
                        if (isSameModule) {
                            return ECall(null, elixirMethodName, callArgs);
                        }
                        return ERemoteCall(makeAST(EVar(moduleName)), elixirMethodName, callArgs);
                        
                    case FStatic(classRef, cf):
                        // Static method call
                        var classType = classRef.get();
                        var className = classType.name;
                        var moduleName = ModuleBuilder.extractModuleName(classType);
                        var methodName = cf.get().name;

                        // Respect `@:native` on the field when present.
                        //
                        // WHY:
                        // - Externs often map Haxe-friendly names to exact Elixir functions,
                        //   including punctuation (`has_key?`, `fetch!`) and full module paths
                        //   (`Task.Supervisor.start_link`). These must not be snake_cased or
                        //   qualified by app-local module rules.
                        //
                        // HOW:
                        // - If field `@:native` contains a dot, treat it as `<Module>.<function>`
                        //   and use that module/function directly.
                        // - Otherwise treat it as the function name only.
                        var nativeFieldName = extractNativeModuleName(cf.get().meta);
                        var resolvedMethodName: Null<String> = null;
                        if (nativeFieldName != null) {
                            var lastDot = nativeFieldName.lastIndexOf(".");
                            if (lastDot != -1) {
                                moduleName = nativeFieldName.substr(0, lastDot);
                                resolvedMethodName = nativeFieldName.substr(lastDot + 1);
                            } else {
                                resolvedMethodName = nativeFieldName;
                            }
                        }

                        // Check for special Haxe standard library calls
                        var specialCall = handleSpecialCall(className, methodName, args, context);
                        if (specialCall != null) {
                            return specialCall;
                        }

                        // Ecto TypedQuery: expand TypedQuery.from(Schema) to raw Ecto.Query.from DSL
                        // WHY: Ensure "from" part of a TypedQuery chain is emitted as proper Ecto code,
                        // so downstream where/order_by transforms receive a valid query AST.
                        // Detect ecto.TypedQuery.from
                        var classPack = classRef.get().pack != null ? classRef.get().pack.join(".") : "";
                        if (className == "TypedQuery" && classPack == "ecto" && methodName == "from") {
                            // Expect signature from<T>(schemaClass: Class<T>)
                            if (args.length >= 1) {
                                // Build a structured AST: Ecto.Query.from(t in Schema, [])
                                // IMPORTANT: Do not emit ERaw here; downstream Ecto/where transforms
                                // need visibility into the query structure.
                                var schemaModuleAst: reflaxe.elixir.ast.ElixirAST = null;
                                switch (args[0].expr) {
                                    case TTypeExpr(TClassDecl(classDecl)):
                                        var cls = classDecl.get();
                                        var nativeName: Null<String> = null;
                                        if (cls.meta.has(":native")) {
                                            var meta = cls.meta.extract(":native");
                                            if (meta != null && meta.length > 0 && meta[0].params != null && meta[0].params.length > 0) {
                                                switch (meta[0].params[0].expr) {
                                                    case EConst(CString(s, _)): nativeName = s;
                                                    default:
                                                }
                                            }
                                        }
                                        var moduleName = nativeName != null ? nativeName : cls.name;
                                        schemaModuleAst = makeAST(EVar(moduleName));
                                    default:
                                        schemaModuleAst = buildExpression(args[0]);
                                }
                                var inExpr = makeAST(EBinary(In, makeAST(EVar("t")), schemaModuleAst));
                                var emptyOpts = makeAST(EList([]));
                                return ERemoteCall(makeAST(EVar("Ecto.Query")), "from", [inExpr, emptyOpts]);
                            }
                        }

	                        // Check for Phoenix-specific patterns
	                        var phoenixCall = handlePhoenixCall(className, methodName, argASTs, context);
	                        if (phoenixCall != null) {
	                            return phoenixCall;
	                        }

                        // Convert method name to snake_case for Elixir function calls unless a
                        // native name was provided (native names are already exact).
                        var elixirMethodName = resolvedMethodName != null
                            ? resolvedMethodName
                            : ElixirNaming.toVarName(methodName);

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
                            return ERemoteCall(makeAST(EVar(moduleName)), elixirMethodName, argASTs);
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
            // DISABLED: trace('[CallExpr] Building idiomatic enum tuple: ${tag} with ${args.length} args');
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
        // DISABLED: trace('[CallExpr] Checking special call: ${className}.${methodName}');
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
                                // Emit a plain Kernel predicate call (e.g. is_integer(value))
                                return ECall(null, typeCheck, [value]);
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
                        // Std.parseInt(str) → case Integer.parse(str) do {num, _} -> num; :error -> nil end
                        if (args.length == 1) {
                            var str = buildExpression(args[0]);
                            var parsed = makeAST(ERemoteCall(makeAST(EVar("Integer")), "parse", [str]));
                            return ECase(parsed, [
                                {pattern: PTuple([PVar("num"), PWildcard]), body: makeAST(EVar("num"))},
                                {pattern: PLiteral(makeAST(EAtom("error"))), body: makeAST(ENil)}
                            ]);
                        }
                        
                    case "parseFloat":
                        // Std.parseFloat(str) → case Float.parse(str) do {num, _} -> num; :error -> nil end
                        if (args.length == 1) {
                            var str = buildExpression(args[0]);
                            var parsed = makeAST(ERemoteCall(makeAST(EVar("Float")), "parse", [str]));
                            return ECase(parsed, [
                                {pattern: PTuple([PVar("num"), PWildcard]), body: makeAST(EVar("num"))},
                                {pattern: PLiteral(makeAST(EAtom("error"))), body: makeAST(ENil)}
                            ]);
                        }
                        
                    case "int":
                        // Std.int(float) → trunc(float)
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            // `trunc/1` is a Kernel function; emit a direct call.
                            return ECall(null, "trunc", [value]);
                        }
                        
                    case "random":
                        // Std.random(max) → if max <= 0, do: 0, else: :rand.uniform(max) - 1
                        // NOTE: :rand.uniform(max) returns 1..max; Std.random(max) must return 0..max-1.
                        if (args.length == 1) {
                            var maxExpr = buildExpression(args[0]);
                            // Evaluate the argument once (Haxe semantics) by binding it per-case clause.
                            // Use a leading-underscore name to minimize outer-scope collisions.
                            var maxVar = "_std_random_max";
                            var maxVarExpr = makeAST(EVar(maxVar));
                            var guard = makeAST(EBinary(LessEqual, maxVarExpr, makeAST(EInteger(0))));
                            var uniform = makeAST(ERemoteCall(makeAST(EAtom("rand")), "uniform", [maxVarExpr]));
                            var value = makeAST(EBinary(Subtract, uniform, makeAST(EInteger(1))));
                            return ECase(maxExpr, [
                                {pattern: PVar(maxVar), guard: guard, body: makeAST(EInteger(0))},
                                {pattern: PVar(maxVar), body: value}
                            ]);
                        }
                }
                
            case "Type":
                switch(methodName) {
                    case "typeof":
                        // Type.typeof(value) → typeof implementation
                        if (args.length == 1) {
                            var value = buildExpression(args[0]);
                            // This would need a helper function in Elixir
                            return ECall(null, "typeof", [value]);
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
                            return ECall(null, "elem", [enumValue, makeAST(EInteger(0))]);
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
    static function handlePhoenixCall(className: String, methodName: String, argASTs: Array<ElixirAST>, context: CompilationContext): Null<ElixirASTDef> {
        
        #if debug_ast_builder
        // DISABLED: trace('[CallExpr] Checking Phoenix call: ${className}.${methodName}');
        #end
        
        // Check for PubSub patterns
        if (StringTools.endsWith(className, "PubSub")) {
            switch(methodName) {
                case "subscribe", "unsubscribe":
                    // Phoenix.PubSub.subscribe/2 and unsubscribe/1 DO NOT take self()
                    var moduleRef = makeAST(EVar(className));
                    return ERemoteCall(moduleRef, methodName, argASTs);

                case "broadcast", "broadcast_from":
                    // broadcast_from/3 takes a process (often self()) as first arg
                    // but we only add self() when the source explicitly provides it.
                    var moduleRef = makeAST(EVar(className));
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Check for Presence patterns
        if (StringTools.endsWith(className, "Presence")) {
            switch(methodName) {
                case "track", "update", "untrack":
                    // Presence operations need self() as first argument
                    var moduleRef = makeAST(EVar(className));
                    var callArgs = (argASTs != null) ? argASTs.copy() : [];
                    var selfCall = makeAST(ECall(null, "self", []));
                    callArgs.unshift(selfCall);
                    
                    return ERemoteCall(moduleRef, methodName, callArgs);
                    
                case "list":
                    // list() doesn't need self()
                    var moduleRef = makeAST(EVar(className));
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Check for LiveView patterns
        if (className == "LiveView" || className == "Phoenix.LiveView") {
            switch(methodName) {
                case "assign", "assign_new", "clear_flash", "put_flash":
                    // These are typically called with socket as first arg
                    var moduleRef = makeAST(EVar("Phoenix.LiveView"));
                    return ERemoteCall(moduleRef, methodName, argASTs);
                    
                case "push_event", "push_patch", "push_redirect":
                    // Event pushing functions
                    var moduleRef = makeAST(EVar("Phoenix.LiveView"));
                    return ERemoteCall(moduleRef, methodName, argASTs);
            }
        }
        
        // Not a Phoenix-specific call
        return null;
    }

    static function resolveStaticCallModuleName(classType: ClassType): String {
        var nativeModuleName = extractNativeModuleName(classType.meta);
        if (nativeModuleName != null) {
            // Extern module calls currently use the "encoded path" convention where
            // method @:native includes the full module path (e.g. "Task.Supervisor.start_link"),
            // and the module reference keeps only the last segment ("Supervisor") so the
            // printer emits `Supervisor.task.supervisor.start_link(...)`.
            if (classType.isExtern && nativeModuleName.indexOf(".") != -1) {
                var parts = nativeModuleName.split(".");
                return parts[parts.length - 1];
            }
            return nativeModuleName;
        }

        // Default behavior: keep the Haxe type name as the module name and rely on
        // later qualification passes (and explicit @:native) for any app/framework
        // namespacing decisions.
        return classType.name;
    }

    static function extractNativeModuleName(meta: MetaAccess): Null<String> {
        if (meta.has(":native")) {
            var nativeMeta = meta.extract(":native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                return switch (nativeMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        // Prefer idiomatic Elixir module aliases (String) over fully-qualified
                        // internal names (Elixir.String) in generated source.
                        StringTools.startsWith(s, "Elixir.") ? s.substr("Elixir.".length) : s;
                    default: null;
                };
            }
        }
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
