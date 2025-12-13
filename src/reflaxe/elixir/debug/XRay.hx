package reflaxe.elixir.debug;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.TypedExprTools;
#end

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

/**
 * Event structure for XRay logging
 */
typedef XRayEvent = {
    id: String,
    timestamp: Float,
    category: String,
    type: String,
    data: Dynamic,
    flowId: Null<String>
}

/**
 * Flow structure for nested tracing
 */
typedef XRayFlow = {
    id: String,
    name: String,
    context: String,
    startTime: Float,
    ?endTime: Float,
    ?duration: Float,
    metadata: Dynamic,
    events: Array<XRayEvent>,
    parent: Null<String>,
    ?summary: Dynamic
}

/**
 * XRay - Comprehensive Compilation Flow Debugging Infrastructure
 * 
 * XRay provides complete visibility into the Reflaxe.Elixir compilation process,
 * enabling rapid identification and resolution of complex compilation issues like
 * Y combinator syntax errors, statement concatenation bugs, and AST transformation problems.
 * 
 * ## Core Philosophy
 * 
 * **"See everything, understand everything, fix everything"**
 * 
 * XRay operates on the principle that debugging compiler issues requires comprehensive
 * visibility into the entire compilation flow - from initial AST processing through
 * final string generation. By capturing every transformation, decision, and context
 * change, XRay enables systematic problem-solving rather than guesswork.
 * 
 * ## Key Capabilities
 * 
 * ### Complete Flow Visualization
 * - **AST Tracking**: Monitor TypedExpr transformations at every compilation stage
 * - **Statement Generation**: Trace how individual statements are created and concatenated
 * - **Context Changes**: Track compilation context (variables, scopes, state) evolution
 * - **Decision Points**: Record why specific compilation choices were made
 * 
 * ### Structured Event Logging
 * - **Categorized Events**: AST, compilation, generation, optimization, error categories
 * - **Hierarchical Tracing**: Nested event tracking for complex transformations
 * - **Timestamp Precision**: Microsecond timing for performance analysis
 * - **JSON Output**: Machine-readable logs for external analysis and visualization
 * 
 * ### Integration Excellence
 * - **DebugHelper Integration**: Seamless integration with existing debug infrastructure
 * - **Conditional Compilation**: Zero production impact via Haxe debug flags
 * - **Performance Optimization**: Minimal overhead when debugging is disabled
 * - **Tool Compatibility**: Designed for IDE integration and external analysis
 * 
 * ## Usage Patterns
 * 
 * ### Enable XRay Debugging
 * ```bash
 * # Enable XRay tracing for all categories
 * npx haxe build.hxml -D debug_xray
 * 
 * # Enable specific XRay categories
 * npx haxe build.hxml -D debug_xray_ast -D debug_xray_statements
 * 
 * # Enable XRay for specific compilation issues
 * npx haxe build.hxml -D debug_xray_y_combinator -D debug_xray_if_expressions
 * ```
 * 
 * ### Use in Compiler Code
 * ```haxe
 * // Trace complete compilation flow
 * XRay.startFlow("Y Combinator Generation", "TypeSafeChildSpec.hx:305-309");
 * 
 * // Track AST transformations
 * XRay.traceAST("TFor Processing", expr, {loopVar: tvar.name, optimization: "Y_COMBINATOR"});
 * 
 * // Monitor statement generation
 * XRay.traceStatement("If Expression", ifStatement, {syntax: "inline", context: "nested"});
 * 
 * // Record compilation decisions
 * XRay.recordDecision("Concatenation Strategy", "append_else_clause", {reason: "incomplete_if", location: "line_48"});
 * 
 * // Complete flow tracking
 * XRay.endFlow("Y Combinator Generation", {success: true, statements: 3});
 * ```
 * 
 * ## Debug Categories
 * 
 * ### Core Categories
 * - **debug_xray**: Enable all XRay tracing (master switch)
 * - **debug_xray_ast**: AST structure and transformation tracking
 * - **debug_xray_statements**: Statement generation and concatenation
 * - **debug_xray_context**: Compilation context and state changes
 * - **debug_xray_decisions**: Compilation decision points and reasoning
 * 
 * ### Issue-Specific Categories
 * - **debug_xray_y_combinator**: Y combinator generation and syntax issues
 * - **debug_xray_if_expressions**: If-expression compilation (inline vs block)
 * - **debug_xray_concatenation**: Statement joining and concatenation bugs
 * - **debug_xray_variables**: Variable tracking and renaming
 * 
 * ### Output Categories
 * - **debug_xray_json**: JSON log output for external analysis
 * - **debug_xray_console**: Real-time console output during compilation
 * - **debug_xray_files**: Write detailed logs to file system
 * 
 * ## Integration with Y Combinator Debugging
 * 
 * XRay is specifically designed to resolve the Y combinator syntax error where
 * `, else: nil` is incorrectly appended to non-if statements. The infrastructure
 * provides the visibility needed to trace the exact concatenation bug location.
 * 
 * ### Y Combinator Debugging Workflow
 * ```haxe
 * // 1. Start comprehensive tracing
 * XRay.startFlow("Y Combinator Debug", "TypeSafeChildSpec compilation");
 * 
 * // 2. Track the problematic for-loop AST
 * XRay.traceAST("Reflect.fields TFor", forExpr, {pattern: "Y_COMBINATOR_CANDIDATE"});
 * 
 * // 3. Monitor if-expression generation
 * XRay.traceStatement("Config Check If", ifExpr, {lines: "48-49", expected: "complete_if"});
 * 
 * // 4. Track statement concatenation
 * XRay.traceConcatenation("Statement Join", [stmt1, stmt2], {location: "lines_71_72"});
 * 
 * // 5. Identify the exact bug location
 * XRay.recordError("Misplaced Else Clause", errorLocation, {root_cause: concatenationBug});
 * ```
 * 
 * @see DebugHelper - Existing debug infrastructure integration
 * @see ElixirCompiler - Main compilation orchestrator
 * @see /docs/03-compiler-development/DEBUG_XRAY_SYSTEM.md - Complete XRay documentation
 */
class XRay {
    
    /**
     * Global XRay session state
     */
    private static var sessionId: String;
    private static var startTime: Float;
    private static var events: Array<XRayEvent> = [];
    private static var flowStack: Array<XRayFlow> = [];
    private static var isInitialized: Bool = false;
    
    /**
     * XRay event categories for structured logging
     */
    public static var categories = {
        AST: "ast",
        STATEMENTS: "statements", 
        CONTEXT: "context",
        DECISIONS: "decisions",
        Y_COMBINATOR: "y_combinator",
        IF_EXPRESSIONS: "if_expressions",
        CONCATENATION: "concatenation",
        VARIABLES: "variables",
        ERRORS: "errors",
        PERFORMANCE: "performance"
    };
    
    /**
     * Initialize XRay debugging session
     * 
     * Creates a new debugging session with unique identifier and timestamp.
     * Must be called before any XRay tracing functions.
     * 
     * @param sessionName Optional session name for identification
     */
    public static function initSession(?sessionName: String): Void {
        #if (debug_xray || debug_compiler)
        if (isInitialized) return;
        
        sessionId = sessionName != null ? sessionName : "xray_" + Std.string(Date.now().getTime());
        startTime = Date.now().getTime();
        events = [];
        flowStack = [];
        isInitialized = true;
        
//         trace('[XRAY:INIT] ====================================================');
        // trace('XRay Session Started: $sessionId');
        // DISABLED: trace('Timestamp: ${Date.now().toString()}');
        // DISABLED: trace('Debug Categories: ${getActiveCategories()}');
//         trace('[XRAY:INIT] ====================================================');
        #end
    }
    
    /**
     * Start a new compilation flow
     * 
     * Begins tracking a high-level compilation flow (e.g., "Y Combinator Generation").
     * Flows can be nested to represent complex compilation hierarchies.
     * 
     * @param flowName Descriptive name for the compilation flow
     * @param context Additional context information (file, line, etc.)
     * @param metadata Optional structured metadata for the flow
     */
    public static function startFlow(flowName: String, context: String, ?metadata: Dynamic): Void {
        #if (debug_xray || debug_compiler)
        ensureInitialized();
        
        var flow: XRayFlow = {
            id: generateFlowId(),
            name: flowName,
            context: context,
            startTime: Date.now().getTime(),
            metadata: metadata,
            events: [],
            parent: flowStack.length > 0 ? flowStack[flowStack.length - 1].id : null
        };
        
        flowStack.push(flow);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:FLOW_START] $flowName');
        // DISABLED: trace('${indent}Context: $context');
        if (metadata != null) trace('${indent}Metadata: ${Json.stringify(metadata)}');
        #end
    }
    
    /**
     * End the current compilation flow
     * 
     * Completes tracking of the current compilation flow and records summary information.
     * 
     * @param flowName Name of the flow to end (for validation)
     * @param summary Optional summary information about the flow results
     */
    public static function endFlow(flowName: String, ?summary: Dynamic): Void {
        #if (debug_xray || debug_compiler)
        if (flowStack.length == 0) {
//             trace('[XRAY:ERROR] Attempted to end flow "$flowName" but no active flows');
            return;
        }
        
        var flow = flowStack.pop();
        if (flow.name != flowName) {
//             trace('[XRAY:WARNING] Flow name mismatch: expected "${flow.name}", got "$flowName"');
        }
        
        flow.endTime = Date.now().getTime();
        flow.duration = flow.endTime - flow.startTime;
        flow.summary = summary;
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:FLOW_END] $flowName');
        // DISABLED: trace('${indent}Duration: ${flow.duration}ms');
        if (summary != null) trace('${indent}Summary: ${Json.stringify(summary)}');
        
        // Add completed flow to events
        recordEvent(categories.PERFORMANCE, "flow_completed", flow);
        #end
    }
    
    /**
     * Trace AST structure and transformations
     * 
     * Records detailed information about TypedExpr AST nodes during compilation.
     * Critical for understanding how AST transformations lead to output issues.
     * 
     * @param context Description of the AST processing context
     * @param expr The TypedExpr being processed
     * @param metadata Additional structured information about the AST
     */
    #if macro
    public static function traceAST(context: String, expr: TypedExpr, ?metadata: Dynamic): Void {
        #if (debug_xray || debug_xray_ast || debug_compiler)
        ensureInitialized();
        
        var astInfo = {
            context: context,
            type: getExpressionTypeName(expr),
            haxeType: getTypeName(expr.t),
            position: expr.pos != null ? '${expr.pos.file}:${expr.pos.min}-${expr.pos.max}' : "unknown",
            structure: getASTStructure(expr),
            metadata: metadata
        };
        
        recordEvent(categories.AST, "ast_trace", astInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:AST] $context');
        // DISABLED: trace('${indent}Type: ${astInfo.type} (${astInfo.haxeType})');
        // DISABLED: trace('${indent}Position: ${astInfo.position}');
        // DISABLED: trace('${indent}Structure: ${astInfo.structure}');
        if (metadata != null) trace('${indent}Metadata: ${Json.stringify(metadata)}');
        #end
    }
    #end
    
    /**
     * Trace statement generation and compilation
     * 
     * Records how individual Elixir statements are generated from AST nodes.
     * Essential for debugging statement concatenation and syntax issues.
     * 
     * @param context Description of the statement generation context
     * @param statement The generated Elixir statement string
     * @param metadata Additional information about statement generation
     */
    public static function traceStatement(context: String, statement: String, ?metadata: Dynamic): Void {
        #if (debug_xray || debug_xray_statements || debug_compiler)
        ensureInitialized();
        
        var stmtInfo = {
            context: context,
            statement: statement,
            length: statement.length,
            lines: statement.split('\n').length,
            metadata: metadata
        };
        
        recordEvent(categories.STATEMENTS, "statement_trace", stmtInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:STATEMENT] $context');
        // DISABLED: trace('${indent}Generated: ${truncateString(statement, 100)}');
        // DISABLED: trace('${indent}Length: ${stmtInfo.length} chars, ${stmtInfo.lines} lines');
        if (metadata != null) trace('${indent}Metadata: ${Json.stringify(metadata)}');
        #end
    }
    
    /**
     * Trace statement concatenation operations
     * 
     * Records how multiple statements are joined together during compilation.
     * Critical for identifying Y combinator syntax concatenation bugs.
     * 
     * @param context Description of the concatenation operation
     * @param statements Array of statements being concatenated
     * @param metadata Information about concatenation strategy and context
     */
    public static function traceConcatenation(context: String, statements: Array<String>, ?metadata: Dynamic): Void {
        #if (debug_xray || debug_xray_concatenation || debug_compiler)
        ensureInitialized();
        
        var concatInfo = {
            context: context,
            statementCount: statements.length,
            statements: statements.map(s -> truncateString(s, 50)),
            totalLength: statements.map(s -> s.length).reduce((a, b) -> a + b, 0),
            metadata: metadata
        };
        
        recordEvent(categories.CONCATENATION, "concatenation_trace", concatInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:CONCAT] $context');
        // DISABLED: trace('${indent}Statements: ${concatInfo.statementCount} (${concatInfo.totalLength} chars total)');
        for (i in 0...statements.length) {
//             trace('${indent}  [$i]: ${concatInfo.statements[i]}');
        }
        if (metadata != null) trace('${indent}Metadata: ${Json.stringify(metadata)}');
        #end
    }
    
    /**
     * Record compilation decision points
     * 
     * Documents why specific compilation choices were made (inline vs block syntax,
     * optimization strategies, etc.). Essential for understanding compilation logic.
     * 
     * @param context Description of the decision being made
     * @param decision The decision that was chosen
     * @param reasoning Structured information about why this decision was made
     */
    public static function recordDecision(context: String, decision: String, reasoning: Dynamic): Void {
        #if (debug_xray || debug_xray_decisions || debug_compiler)
        ensureInitialized();
        
        var decisionInfo = {
            context: context,
            decision: decision,
            reasoning: reasoning,
            timestamp: Date.now().getTime()
        };
        
        recordEvent(categories.DECISIONS, "decision_recorded", decisionInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:DECISION] $context');
        // DISABLED: trace('${indent}Decision: $decision');
        // DISABLED: trace('${indent}Reasoning: ${Json.stringify(reasoning)}');
        #end
    }
    
    /**
     * Record compilation errors and issues
     * 
     * Documents compilation errors, warnings, and unexpected conditions.
     * Provides structured error information for debugging.
     * 
     * @param context Description of where the error occurred
     * @param error The error or issue that was encountered
     * @param details Additional structured information about the error
     */
    public static function recordError(context: String, error: String, details: Dynamic): Void {
        #if (debug_xray || debug_compiler)
        ensureInitialized();
        
        var errorInfo = {
            context: context,
            error: error,
            details: details,
            timestamp: Date.now().getTime(),
            flowStack: flowStack.map(f -> f.name)
        };
        
        recordEvent(categories.ERRORS, "error_recorded", errorInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:ERROR] $context');
        // DISABLED: trace('${indent}Error: $error');
        // DISABLED: trace('${indent}Details: ${Json.stringify(details)}');
        // DISABLED: trace('${indent}Flow Stack: ${errorInfo.flowStack.join(" → ")}');
        #end
    }
    
    /**
     * Track Y combinator specific patterns
     * 
     * Specialized tracing for Y combinator generation and related syntax issues.
     * Provides targeted debugging for the primary issue we're solving.
     * 
     * @param context Description of the Y combinator processing
     * @param pattern The pattern being processed (loop detection, optimization, etc.)
     * @param details Information about the Y combinator generation
     */
    public static function traceYCombinator(context: String, pattern: String, details: Dynamic): Void {
        #if (debug_xray || debug_xray_y_combinator || debug_y_combinator || debug_compiler)
        ensureInitialized();
        
        var yCombInfo = {
            context: context,
            pattern: pattern,
            details: details,
            timestamp: Date.now().getTime()
        };
        
        recordEvent(categories.Y_COMBINATOR, "y_combinator_trace", yCombInfo);
        
        var indent = getIndentation();
//         trace('${indent}[XRAY:Y_COMBINATOR] $context');
        // DISABLED: trace('${indent}Pattern: $pattern');
        // DISABLED: trace('${indent}Details: ${Json.stringify(details)}');
        #end
    }
    
    /**
     * Export XRay session data
     * 
     * Generates a complete JSON export of all XRay events and flows for external analysis.
     * Enables detailed post-compilation analysis and visualization.
     * 
     * @param filePath Optional file path to write JSON export
     * @return Complete session data as JSON string
     */
    public static function exportSession(?filePath: String): String {
        #if (debug_xray || debug_xray_json || debug_compiler)
        ensureInitialized();
        
        var sessionData = {
            sessionId: sessionId,
            startTime: startTime,
            endTime: Date.now().getTime(),
            duration: Date.now().getTime() - startTime,
            totalEvents: events.length,
            categories: getEventCategoryCounts(),
            events: events,
            activeCategories: getActiveCategories()
        };
        
        var json = Json.stringify(sessionData, null, "  ");
        
        if (filePath != null) {
            try {
                // Ensure directory exists
                var dir = haxe.io.Path.directory(filePath);
                if (!FileSystem.exists(dir)) {
                    FileSystem.createDirectory(dir);
                }
                
                File.saveContent(filePath, json);
//                 trace('[XRAY:EXPORT] Session data exported to: $filePath');
            } catch (e: Dynamic) {
//                 trace('[XRAY:ERROR] Failed to write session export: $e');
            }
        }
        
        return json;
        #else
        return "{}";
        #end
    }
    
    /**
     * Generate summary report of XRay session
     * 
     * Creates a human-readable summary of the debugging session for quick analysis.
     * 
     * @return Summary report string
     */
    public static function generateSummary(): String {
        #if (debug_xray || debug_compiler)
        ensureInitialized();
        
        var summary = [];
        summary.push('XRay Session Summary');
        summary.push('===================');
        summary.push('Session ID: $sessionId');
        summary.push('Duration: ${Date.now().getTime() - startTime}ms');
        summary.push('Total Events: ${events.length}');
        summary.push('');
        
        var categories = getEventCategoryCounts();
        summary.push('Event Categories:');
        for (category in Reflect.fields(categories)) {
            var count = Reflect.field(categories, category);
            summary.push('  $category: $count');
        }
        summary.push('');
        
        if (events.length > 0) {
            summary.push('Recent Events:');
            var recentEvents = events.slice(-5);
            for (event in recentEvents) {
                summary.push('  [${event.category}] ${event.type}: ${event.data.context}');
            }
        }
        
        return summary.join('\n');
        #else
        return "XRay debugging disabled";
        #end
    }
    
    // ============================================================================
    // PRIVATE IMPLEMENTATION
    // ============================================================================
    
    private static function ensureInitialized(): Void {
        if (!isInitialized) {
            initSession();
        }
    }
    
    private static function recordEvent(category: String, type: String, data: Dynamic): Void {
        var event: XRayEvent = {
            id: generateEventId(),
            timestamp: Date.now().getTime(),
            category: category,
            type: type,
            data: data,
            flowId: flowStack.length > 0 ? flowStack[flowStack.length - 1].id : null
        };
        
        events.push(event);
        
        // Add event to current flow if one exists
        if (flowStack.length > 0) {
            flowStack[flowStack.length - 1].events.push(event);
        }
    }
    
    private static function generateEventId(): String {
        return "evt_" + Std.string(Date.now().getTime()) + "_" + Std.string(Math.random() * 1000);
    }
    
    private static function generateFlowId(): String {
        return "flow_" + Std.string(Date.now().getTime()) + "_" + Std.string(Math.random() * 1000);
    }
    
    private static function getIndentation(): String {
        var depth = flowStack.length;
        var indent = "";
        for (i in 0...depth) {
            indent += "  ";
        }
        return indent;
    }
    
    private static function truncateString(str: String, maxLength: Int): String {
        if (str.length <= maxLength) return str;
        return str.substring(0, maxLength - 3) + "...";
    }
    
    private static function getActiveCategories(): Array<String> {
        var active = [];
        
        #if debug_xray active.push("debug_xray"); #end
        #if debug_xray_ast active.push("debug_xray_ast"); #end
        #if debug_xray_statements active.push("debug_xray_statements"); #end
        #if debug_xray_context active.push("debug_xray_context"); #end
        #if debug_xray_decisions active.push("debug_xray_decisions"); #end
        #if debug_xray_y_combinator active.push("debug_xray_y_combinator"); #end
        #if debug_xray_if_expressions active.push("debug_xray_if_expressions"); #end
        #if debug_xray_concatenation active.push("debug_xray_concatenation"); #end
        #if debug_xray_variables active.push("debug_xray_variables"); #end
        #if debug_xray_json active.push("debug_xray_json"); #end
        #if debug_xray_console active.push("debug_xray_console"); #end
        #if debug_xray_files active.push("debug_xray_files"); #end
        
        return active;
    }
    
    private static function getEventCategoryCounts(): Dynamic {
        var counts = {};
        for (event in events) {
            var current = Reflect.hasField(counts, event.category) ? Reflect.field(counts, event.category) : 0;
            Reflect.setField(counts, event.category, current + 1);
        }
        return counts;
    }
    
    #if macro
    private static function getExpressionTypeName(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TConst(_): "TConst";
            case TLocal(_): "TLocal";
            case TArray(_, _): "TArray";
            case TBinop(_, _, _): "TBinop";
            case TField(_, _): "TField";
            case TTypeExpr(_): "TTypeExpr";
            case TParenthesis(_): "TParenthesis";
            case TObjectDecl(_): "TObjectDecl";
            case TArrayDecl(_): "TArrayDecl";
            case TCall(_, _): "TCall";
            case TNew(_, _, _): "TNew";
            case TUnop(_, _, _): "TUnop";
            case TFunction(_): "TFunction";
            case TVar(_, _): "TVar";
            case TBlock(_): "TBlock";
            case TFor(_, _, _): "TFor";
            case TIf(_, _, _): "TIf";
            case TWhile(_, _, _): "TWhile";
            case TSwitch(_, _, _): "TSwitch";
            case TTry(_, _): "TTry";
            case TReturn(_): "TReturn";
            case TBreak: "TBreak";
            case TContinue: "TContinue";
            case TThrow(_): "TThrow";
            case TCast(_, _): "TCast";
            case TMeta(_, _): "TMeta";
            case TEnumParameter(_, _, _): "TEnumParameter";
            case TEnumIndex(_): "TEnumIndex";
            case TIdent(_): "TIdent";
        }
    }
    
    private static function getTypeName(type: Type): String {
        return switch (type) {
            case TInst(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TEnum(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TType(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TFun(args, ret): '(${args.map(a -> '${a.name}:${getTypeName(a.t)}').join(", ")}) -> ${getTypeName(ret)}';
            case TMono(t): t.get() != null ? getTypeName(t.get()) : "Unknown";
            case TAbstract(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TDynamic(t): t != null ? 'Dynamic<${getTypeName(t)}>' : "Dynamic";
            case TLazy(f): getTypeName(f());
            case TAnonymous(a): "Anonymous";
        }
    }
    
    private static function getASTStructure(expr: TypedExpr, depth: Int = 0): String {
        if (depth > 2) return "..."; // Prevent deep recursion
        
        var typeName = getExpressionTypeName(expr);
        
        return switch (expr.expr) {
            case TBlock(exprs):
                '$typeName[${exprs.length} exprs]';
            case TCall(e, args):
                '$typeName(${getExpressionTypeName(e)}, [${args.length} args])';
            case TFor(tvar, iterExpr, blockExpr):
                '$typeName(${tvar.name}, ${getExpressionTypeName(iterExpr)}, ${getExpressionTypeName(blockExpr)})';
            case TIf(cond, eif, eelse):
                '$typeName(${getExpressionTypeName(cond)}, ${getExpressionTypeName(eif)}, ${eelse != null ? getExpressionTypeName(eelse) : "null"})';
            case TBinop(op, e1, e2):
                '$typeName(${op}, ${getExpressionTypeName(e1)}, ${getExpressionTypeName(e2)})';
            case _:
                typeName;
        }
    }
    #end
}
