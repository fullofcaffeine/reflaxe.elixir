package test;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.PatternMatcher;
import reflaxe.elixir.helpers.GuardCompiler;
#end

/**
 * TRUE MACRO-TIME UNIT TESTS for ElixirCompiler
 * 
 * These tests ACTUALLY run at compile-time and test the real compiler!
 * No mocks needed - we're testing the actual implementation.
 */
class MacroTimeCompilerTest {
    
    public static function main() {
        #if macro
        // Run tests AT COMPILE TIME using utest's MacroRunner
        trace("🔧 Running Macro-Time Compiler Tests...");
        
        // We could use utest.MacroRunner here
        // utest.MacroRunner.run(MacroTimeCompilerTest);
        
        // Or run tests directly at compile-time
        runMacroTimeTests();
        #else
        trace("This test only runs at macro-time. Compile with macro context to test.");
        #end
    }
    
    #if macro
    static function runMacroTimeTests() {
        var passed = 0;
        var failed = 0;
        
        // Test 1: Real ElixirCompiler instantiation
        try {
            var compiler = new ElixirCompiler();
            trace("✅ ElixirCompiler instantiation");
            passed++;
        } catch (e: Dynamic) {
            trace("❌ ElixirCompiler instantiation failed: " + e);
            failed++;
        }
        
        // Test 2: Test PatternMatcher with real AST
        try {
            var matcher = new PatternMatcher();
            // Create a REAL macro expression
            var expr = macro { 
                switch(x) {
                    case Some(v): v;
                    case None: null;
                }
            };
            // Test with real AST!
            var result = matcher.processPattern(expr);
            trace("✅ PatternMatcher processes real AST");
            passed++;
        } catch (e: Dynamic) {
            trace("❌ PatternMatcher failed: " + e);
            failed++;
        }
        
        // Test 3: Test GuardCompiler with real guard expressions
        try {
            var guard = new GuardCompiler();
            var guardExpr = macro x > 0 && x < 100;
            var compiled = guard.compileGuard(guardExpr);
            if (compiled.indexOf("when") >= 0) {
                trace("✅ GuardCompiler generates guards");
                passed++;
            } else {
                trace("❌ GuardCompiler output incorrect");
                failed++;
            }
        } catch (e: Dynamic) {
            trace("❌ GuardCompiler failed: " + e);
            failed++;
        }
        
        // Test 4: Test actual expression compilation
        try {
            var compiler = new ElixirCompiler();
            // Create a real variable declaration
            var varExpr = macro var name = "test";
            var result = compiler.compileExpression(varExpr);
            if (result.indexOf("name = \"test\"") >= 0) {
                trace("✅ Variable compilation works");
                passed++;
            } else {
                trace("❌ Variable compilation incorrect");
                failed++;
            }
        } catch (e: Dynamic) {
            trace("❌ Expression compilation failed: " + e);
            failed++;
        }
        
        // Test 5: Test function compilation
        try {
            var compiler = new ElixirCompiler();
            var funcExpr = macro {
                function greet(name: String): String {
                    return "Hello, " + name;
                }
            };
            var result = compiler.compileExpression(funcExpr);
            if (result.indexOf("def greet(name)") >= 0) {
                trace("✅ Function compilation works");
                passed++;
            } else {
                trace("❌ Function compilation incorrect");
                failed++;
            }
        } catch (e: Dynamic) {
            trace("❌ Function compilation failed: " + e);
            failed++;
        }
        
        // Summary
        trace("");
        trace("🎯 Macro-Time Test Results:");
        trace("   Passed: " + passed);
        trace("   Failed: " + failed);
        
        // If any tests failed, cause a compilation error
        if (failed > 0) {
            Context.error("Macro-time tests failed! See trace output above.", Context.currentPos());
        }
    }
    #end
}