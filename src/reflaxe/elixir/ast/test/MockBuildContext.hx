package reflaxe.elixir.ast.test;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.ast.context.ElixirASTContext;

/**
 * MockBuildContext: Test implementation of BuildContext for unit testing builders
 *
 * WHY: As recommended by Codex, modular builders need to be testable in isolation.
 * This mock context allows testing builders without the full compiler infrastructure.
 *
 * WHAT: Provides a controlled test environment for builders:
 * - Configurable variable mappings
 * - Test-specific feature flags
 * - Assertion helpers for verifying builder behavior
 * - Stub implementations of all BuildContext methods
 *
 * HOW: Implements BuildContext with controllable behavior:
 * - Pre-configured responses for variable resolution
 * - Recording of method calls for verification
 * - Simplified implementations without side effects
 *
 * ARCHITECTURE BENEFITS:
 * - Unit test builders without full compiler
 * - Fast, focused tests
 * - Easy to debug failures
 * - Clear test intentions
 *
 * @see Codex architectural recommendations for testable builders
 */
class MockBuildContext implements BuildContext {
    // Test configuration
    private var variableMap: Map<Int, String>;
    private var patternVariables: Map<Int, String>;
    private var featureFlags: Map<String, Bool>;
    private var recordedCalls: Array<String>;
    private var nextNodeId: Int;

    // Mock AST context
    private var astContext: ElixirASTContext;

    public function new() {
        variableMap = new Map();
        patternVariables = new Map();
        featureFlags = new Map();
        recordedCalls = [];
        nextNodeId = 0;
        astContext = new ElixirASTContext();
    }

    // ===== Test Configuration Methods =====

    /**
     * Configure a variable mapping for testing
     */
    public function addVariableMapping(tvarId: Int, name: String): Void {
        variableMap.set(tvarId, name);
    }

    /**
     * Configure a pattern variable for testing
     */
    public function addPatternVariable(tvarId: Int, name: String): Void {
        patternVariables.set(tvarId, name);
    }

    /**
     * Set a feature flag for testing
     */
    public function setTestFeatureFlag(flag: String, enabled: Bool): Void {
        featureFlags.set(flag, enabled);
    }

    /**
     * Get recorded method calls for verification
     */
    public function getRecordedCalls(): Array<String> {
        return recordedCalls.copy();
    }

    /**
     * Clear recorded calls
     */
    public function clearRecordedCalls(): Void {
        recordedCalls = [];
    }

    // ===== BuildContext Implementation =====

    public function getASTContext(): ElixirASTContext {
        recordedCalls.push("getASTContext");
        return astContext;
    }

    public function resolveVariable(tvarId: Int, defaultName: String): String {
        recordedCalls.push('resolveVariable($tvarId, $defaultName)');

        // Priority: Pattern > Mapped > Default
        if (patternVariables.exists(tvarId)) {
            return patternVariables.get(tvarId);
        }
        if (variableMap.exists(tvarId)) {
            return variableMap.get(tvarId);
        }
        return defaultName;
    }

    public function registerPatternVariable(tvarId: Int, patternName: String): Void {
        recordedCalls.push('registerPatternVariable($tvarId, $patternName)');
        patternVariables.set(tvarId, patternName);
    }

    public function getCurrentPosition(): Position {
        recordedCalls.push("getCurrentPosition");
        // Return mock position
        return {
            file: "test.hx",
            min: 0,
            max: 0
        };
    }

    public function setCurrentPosition(pos: Position): Void {
        recordedCalls.push("setCurrentPosition");
    }

    public function getCurrentModule(): Null<ModuleType> {
        recordedCalls.push("getCurrentModule");
        return null; // Simplified for testing
    }

    public function getCurrentClass(): Null<ClassType> {
        recordedCalls.push("getCurrentClass");
        return null; // Simplified for testing
    }

    public function generateNodeId(): String {
        recordedCalls.push("generateNodeId");
        return 'test_node_${nextNodeId++}';
    }

    public function isIdiomaticEnum(enumType: EnumType): Bool {
        recordedCalls.push('isIdiomaticEnum(${enumType.name})');
        // Default to false for testing unless configured
        return enumType.meta.has(":elixirIdiomatic");
    }

    public function getClauseContext(caseIndex: Int): ClauseContext {
        recordedCalls.push('getClauseContext($caseIndex)');
        return new ClauseContext();
    }

    public function pushClauseContext(ctx: ClauseContext): Void {
        recordedCalls.push("pushClauseContext");
        // No-op for testing
    }

    public function popClauseContext(): Null<ClauseContext> {
        recordedCalls.push("popClauseContext");
        return new ClauseContext();
    }

    public function isInPattern(): Bool {
        recordedCalls.push("isInPattern");
        return astContext.isInPattern;
    }

    public function setInPattern(inPattern: Bool): Void {
        recordedCalls.push('setInPattern($inPattern)');
        astContext.isInPattern = inPattern;
    }

    public function getCurrentFunction(): Null<ClassField> {
        recordedCalls.push("getCurrentFunction");
        return null; // Simplified for testing
    }

    public function warning(message: String, ?pos: Position): Void {
        recordedCalls.push('warning: $message');
    }

    public function error(message: String, ?pos: Position): Void {
        recordedCalls.push('error: $message');
        throw 'Test error: $message';
    }

    public function getExpressionBuilder(): (TypedExpr) -> ElixirAST {
        recordedCalls.push("getExpressionBuilder");
        // Return simple stub builder
        return function(expr: TypedExpr): ElixirAST {
            return ElixirAST.makeAST(EVar("test_expr"));
        };
    }

    public function getPatternBuilder(clauseContext: ClauseContext): (TypedExpr) -> ElixirAST {
        recordedCalls.push("getPatternBuilder");
        return function(expr: TypedExpr): ElixirAST {
            return ElixirAST.makeAST(EVar("test_pattern"));
        };
    }

    public function isFeatureEnabled(flag: String): Bool {
        recordedCalls.push('isFeatureEnabled($flag)');
        return featureFlags.exists(flag) && featureFlags.get(flag);
    }

    public function setFeatureFlag(flag: String, enabled: Bool): Void {
        recordedCalls.push('setFeatureFlag($flag, $enabled)');
        featureFlags.set(flag, enabled);
    }

    // ===== Test Assertion Helpers =====

    /**
     * Assert that a method was called
     */
    public function assertCalled(methodName: String): Bool {
        for (call in recordedCalls) {
            if (call.indexOf(methodName) >= 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * Assert that a method was called with specific arguments
     */
    public function assertCalledWith(expected: String): Bool {
        return recordedCalls.indexOf(expected) >= 0;
    }

    /**
     * Get number of times a method was called
     */
    public function getCallCount(methodName: String): Int {
        var count = 0;
        for (call in recordedCalls) {
            if (call.indexOf(methodName) >= 0) {
                count++;
            }
        }
        return count;
    }
}

#end
