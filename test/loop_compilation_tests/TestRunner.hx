package loop_compilation_tests;

/**
 * TestRunner: Main entry point for loop compilation tests
 * 
 * Executes all loop test categories and reports results.
 * This helps establish baseline behavior before refactoring.
 */
class TestRunner {
    public static function main() {
        trace("=== Loop Compilation Test Suite ===");
        
        // Basic Loops
        trace("\n--- Basic Loops ---");
        trace("Basic for loop: " + BasicLoops.testBasicForLoop());
        trace("Basic while loop: " + BasicLoops.testBasicWhileLoop());
        trace("Do-while loop: " + BasicLoops.testDoWhileLoop());
        trace("For-in array: " + BasicLoops.testForInArray());
        trace("Reverse loop: " + BasicLoops.testReverseForLoop());
        
        // Nested Loops
        trace("\n--- Nested Loops ---");
        trace("Nested for loops: " + NestedLoops.testNestedForLoops());
        trace("Nested while loops: " + NestedLoops.testNestedWhileLoops());
        trace("Mixed nesting: " + NestedLoops.testMixedNesting());
        trace("Triple nesting: " + NestedLoops.testTripleNesting());
        trace("Nested with break: " + NestedLoops.testNestedWithBreak());
        
        // Control Flow
        trace("\n--- Loop Control Flow ---");
        trace("Break in for: " + LoopControlFlow.testBreakInFor());
        trace("Break in while: " + LoopControlFlow.testBreakInWhile());
        trace("Continue in for: " + LoopControlFlow.testContinueInFor());
        trace("Continue in while: " + LoopControlFlow.testContinueInWhile());
        trace("Break in nested: " + LoopControlFlow.testBreakInNested());
        trace("Return from loop: " + LoopControlFlow.testReturnFromLoop());
        trace("Multiple break conditions: " + LoopControlFlow.testMultipleBreakConditions());
        
        // Array Patterns
        trace("\n--- Array Patterns ---");
        trace("Simple map: " + ArrayPatterns.testSimpleMap());
        trace("Simple filter: " + ArrayPatterns.testSimpleFilter());
        trace("Map filter: " + ArrayPatterns.testMapFilter());
        trace("Array comprehension: " + ArrayPatterns.testArrayComprehension());
        trace("Conditional comprehension: " + ArrayPatterns.testConditionalComprehension());
        trace("Nested comprehension: " + ArrayPatterns.testNestedComprehension());
        trace("Reduce pattern: " + ArrayPatterns.testReduce());
        trace("Find pattern: " + ArrayPatterns.testFindPattern());
        trace("Indexed iteration: " + ArrayPatterns.testIndexedIteration());
        trace("Reverse iteration: " + ArrayPatterns.testReverseIteration());
        
        // Loop Variables
        trace("\n--- Loop Variables ---");
        trace("Variable capture functions count: " + LoopVariables.testVariableCapture().length);
        trace("Shadowing: " + LoopVariables.testShadowing());
        trace("Multiple iterators: " + LoopVariables.testMultipleIterators());
        trace("Loop variable mutation: " + LoopVariables.testLoopVariableMutation());
        trace("Outer scope modification: " + LoopVariables.testOuterScopeModification());
        trace("Complex variable mapping: " + LoopVariables.testComplexVariableMapping());
        trace("Variable reuse: " + LoopVariables.testVariableReuseAcrossLoops());
        trace("Loop in lambda: " + LoopVariables.testLoopInLambda());
        
        // Edge Cases
        trace("\n--- Edge Cases ---");
        trace("Empty loop: " + EdgeCases.testEmptyLoop());
        trace("Single iteration: " + EdgeCases.testSingleIteration());
        trace("Negative range: " + EdgeCases.testNegativeRange());
        trace("Infinite with break: " + EdgeCases.testInfiniteWithBreak());
        trace("Empty array: " + EdgeCases.testEmptyArray());
        trace("Null check: " + EdgeCases.testNullCheck());
        trace("Complex condition: " + EdgeCases.testComplexCondition());
        trace("No body loop: " + EdgeCases.testNoBodyLoop());
        trace("Large iteration sum: " + EdgeCases.testLargeIteration());
        trace("Break in else: " + EdgeCases.testBreakInElse());
        trace("Continue as last: " + EdgeCases.testContinueAsLastStatement());
        trace("Loop with exception: " + EdgeCases.testLoopWithException());
        
        trace("\n=== All Loop Tests Complete ===");
    }
}