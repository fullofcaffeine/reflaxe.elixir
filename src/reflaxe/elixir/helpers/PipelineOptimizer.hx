package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;

using StringTools;

/**
 * Represents a pipeline pattern detected in the AST
 */
typedef PipelinePattern = {
    var variable: String;
    var operations: Array<PipelineOperation>;
    var isChain: Bool; // true for method chains, false for sequential assignments
}

typedef PipelineOperation = {
    var functionName: String;
    var arguments: Array<String>;
    var isBuiltin: Bool; // true for Enum.map, String.trim, etc.
}

/**
 * Advanced pipeline detection and generation for idiomatic Elixir code
 * 
 * This class analyzes TypedExpr AST to detect patterns that should be
 * compiled to Elixir pipeline operators for maximum idiomaticity.
 * 
 * Key patterns detected:
 * - Sequential operations on same variable (socket = f(socket, ...))
 * - Method chaining patterns (data.map().filter().reduce())
 * - Phoenix LiveView assign chains
 * - Enum operations that should use pipelines
 */
class PipelineOptimizer {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Detect pipeline opportunities in a sequence of statements
     * 
     * Looks for patterns like:
     * - socket = assign(socket, :key1, value1)
     * - socket = assign(socket, :key2, value2)
     * 
     * And converts to:
     * socket |> assign(:key1, value1) |> assign(:key2, value2)
     */
    public function detectPipelinePattern(statements: Array<TypedExpr>): Null<PipelinePattern> {
        if (statements.length < 2) return null;
        
        var patterns = [];
        var currentVariable: String = null;
        var operations: Array<PipelineOperation> = [];
        
        for (i in 0...statements.length) {
            var stmt = statements[i];
            var pipelineOp = extractPipelineOperation(stmt);
            
            if (pipelineOp != null) {
                if (currentVariable == null) {
                    currentVariable = pipelineOp.targetVariable;
                    operations.push(pipelineOp.operation);
                } else if (currentVariable == pipelineOp.targetVariable) {
                    // Same variable - add to pipeline
                    operations.push(pipelineOp.operation);
                } else {
                    // Different variable - finish current pipeline
                    if (operations.length >= 2) {
                        patterns.push({
                            variable: currentVariable,
                            operations: operations,
                            isChain: false
                        });
                    }
                    
                    // Start new pipeline
                    currentVariable = pipelineOp.targetVariable;
                    operations = [pipelineOp.operation];
                }
            } else {
                // Not a pipeline operation - finish current pipeline if any
                if (currentVariable != null && operations.length >= 2) {
                    patterns.push({
                        variable: currentVariable,
                        operations: operations,
                        isChain: false
                    });
                }
                currentVariable = null;
                operations = [];
            }
        }
        
        // Handle final pipeline
        if (currentVariable != null && operations.length >= 2) {
            patterns.push({
                variable: currentVariable,
                operations: operations,
                isChain: false
            });
        }
        
        return patterns.length > 0 ? patterns[0] : null;
    }
    
    /**
     * Extract pipeline operation from a statement
     * Returns null if this isn't a pipeline-able operation
     */
    private function extractPipelineOperation(expr: TypedExpr): Null<{targetVariable: String, operation: PipelineOperation}> {
        return switch(expr.expr) {
            case TVar(v, init) if (init != null):
                // var x = f(x, ...)
                var varName = v.name;
                var operation = extractOperation(init, varName);
                if (operation != null) {
                    return {targetVariable: varName, operation: operation};
                }
                null;
                
            case TBinop(OpAssign, {expr: TLocal(v)}, right):
                // x = f(x, ...)
                var varName = v.name;
                var operation = extractOperation(right, varName);
                if (operation != null) {
                    return {targetVariable: varName, operation: operation};
                }
                null;
                
            default:
                null;
        }
    }
    
    /**
     * Extract operation that could be part of a pipeline
     */
    private function extractOperation(expr: TypedExpr, expectedFirstArg: String): Null<PipelineOperation> {
        return switch(expr.expr) {
            case TCall(func, args):
                var funcName = getFunctionName(func);
                if (funcName != null && args.length > 0) {
                    var firstArg = getExpressionString(args[0]);
                    if (firstArg == expectedFirstArg) {
                        // This is a pipeline candidate
                        var restArgs = [for (i in 1...args.length) getExpressionString(args[i])];
                        return {
                            functionName: funcName,
                            arguments: restArgs,
                            isBuiltin: isBuiltinFunction(funcName)
                        };
                    }
                }
                null;
                
            default:
                null;
        }
    }
    
    /**
     * Get function name from a TypedExpr
     */
    private function getFunctionName(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TField(_, fa):
                switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                }
            case TLocal(v):
                v.name;
            default:
                null;
        };
    }
    
    /**
     * Convert TypedExpr to string representation
     */
    private function getExpressionString(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TLocal(v): v.name;
            case TConst(TString(s)): '"$s"';
            case TConst(TInt(i)): Std.string(i);
            case TConst(TFloat(f)): Std.string(f);
            case TConst(TBool(b)): Std.string(b);
            case TField(e, field): getExpressionString(e) + "." + field;
            case TArrayDecl(_) | TObjectDecl(_) | TCall(_, _):
                // For complex expressions, delegate to the main compiler
                compiler.compileExpression(expr);
            default: "expr"; // Fallback
        }
    }
    
    /**
     * Check if a function is a builtin that should use modules
     */
    private function isBuiltinFunction(funcName: String): Bool {
        var builtins = [
            "assign", "push_event", "push_patch", // Phoenix LiveView
            "map", "filter", "reduce", "reject", "find", // Enum
            "trim", "downcase", "upcase", "split", // String
            "put", "get", "merge", "delete", // Map
            "where", "order_by", "group_by", "having", "select", "from", "join", "limit", "offset" // Ecto Query functions
        ];
        return builtins.indexOf(funcName) != -1;
    }
    
    /**
     * Compile a pipeline pattern to idiomatic Elixir
     */
    public function compilePipeline(pattern: PipelinePattern): String {
        if (pattern.operations.length == 0) return "";
        
        var result = pattern.variable;
        
        for (i in 0...pattern.operations.length) {
            var op = pattern.operations[i];
            result += "\n  |> " + compilePipelineOperation(op);
        }
        
        return result;
    }
    
    /**
     * Compile a single pipeline operation
     */
    private function compilePipelineOperation(op: PipelineOperation): String {
        var args = op.arguments.length > 0 ? "(" + op.arguments.join(", ") + ")" : "()";
        
        // Use appropriate module for builtin functions
        return switch(op.functionName) {
            case "assign" | "push_event" | "push_patch":
                op.functionName + args;
            case "map" | "filter" | "reduce" | "reject" | "find":
                "Enum." + op.functionName + args;
            case "trim" | "downcase" | "upcase" | "split":
                "String." + op.functionName + args;
            case "put" | "get" | "merge" | "delete":
                "Map." + op.functionName + args;
            case "where" | "order_by" | "group_by" | "having" | "select" | "from" | "join" | "limit" | "offset":
                // These are Ecto query functions that don't need module prefix in pipelines
                op.functionName + args;
            default:
                // For any other function, use as-is (let the main compiler handle module resolution)
                op.functionName + args;
        }
    }
    
    /**
     * Detect method chaining patterns
     * For expressions like: data.map(f).filter(g).reduce(h)
     */
    public function detectMethodChain(expr: TypedExpr): Null<PipelinePattern> {
        var chain = extractMethodChain(expr);
        if (chain.length >= 2) {
            var operations = [];
            var baseVar = "data"; // Could be enhanced to extract actual variable
            
            for (method in chain) {
                operations.push({
                    functionName: method.name,
                    arguments: method.args,
                    isBuiltin: isBuiltinFunction(method.name)
                });
            }
            
            return {
                variable: baseVar,
                operations: operations,
                isChain: true
            };
        }
        
        return null;
    }
    
    /**
     * Extract method chain from expression
     */
    private function extractMethodChain(expr: TypedExpr): Array<{name: String, args: Array<String>}> {
        var chain = [];
        
        function traverse(e: TypedExpr): Void {
            switch(e.expr) {
                case TCall({expr: TField(obj, fa)}, args):
                    traverse(obj); // Process the object first
                    var argStrings = [for (arg in args) getExpressionString(arg)];
                    var fieldName = switch(fa) {
                        case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                            cf.get().name;
                        case FDynamic(s):
                            s;
                        case FEnum(_, ef):
                            ef.name;
                    };
                    chain.push({name: fieldName, args: argStrings});
                    
                case TField(obj, _):
                    traverse(obj);
                    
                default:
                    // Base case - stop traversing
            }
        }
        
        traverse(expr);
        return chain;
    }
    
    /**
     * Check if a sequence of statements should use pipelines
     */
    public function shouldUsePipeline(statements: Array<TypedExpr>): Bool {
        var pattern = detectPipelinePattern(statements);
        return pattern != null && pattern.operations.length >= 2;
    }
    
    /**
     * Get optimized import list based on detected patterns
     */
    public function getRequiredImports(patterns: Array<PipelinePattern>): Array<String> {
        var imports = [];
        var modules = new Map<String, Array<String>>();
        
        for (pattern in patterns) {
            for (op in pattern.operations) {
                switch(op.functionName) {
                    case "assign" | "push_event" | "push_patch":
                        if (!modules.exists("Phoenix.LiveView")) {
                            modules.set("Phoenix.LiveView", []);
                        }
                        modules.get("Phoenix.LiveView").push(op.functionName);
                        
                    case "map" | "filter" | "reduce" | "reject" | "find":
                        if (!modules.exists("Enum")) {
                            modules.set("Enum", []);
                        }
                        modules.get("Enum").push(op.functionName);
                }
            }
        }
        
        // Generate import statements
        for (module in modules.keys()) {
            var functions = modules.get(module);
            if (functions.length > 0) {
                var uniqueFuncs = [];
                for (func in functions) {
                    if (uniqueFuncs.indexOf(func) == -1) {
                        uniqueFuncs.push(func);
                    }
                }
                imports.push('import $module, only: [${uniqueFuncs.map(f -> f + ": 2").join(", ")}]');
            }
        }
        
        return imports;
    }
}

#end