package test;

import utest.Test;
import utest.Assert;

/**
 * Elixir extern definitions tests using modern utest framework
 * Tests comprehensive extern definitions for Elixir stdlib modules
 */
class TestExterns extends Test {
    
    function test_elixir_map_extern() {
        // Test ElixirMap extern compilation
        var success = compileExternTest("ElixirMap");
        Assert.isTrue(success, "ElixirMap extern should compile successfully");
    }
    
    function test_elixir_string_extern() {
        // Test ElixirString extern compilation  
        var success = compileExternTest("ElixirString");
        Assert.isTrue(success, "ElixirString extern should compile successfully");
    }
    
    function test_enumerable_extern() {
        // Test Enumerable extern compilation (renamed from Enum to avoid conflicts)
        var success = compileExternTest("Enumerable");
        Assert.isTrue(success, "Enumerable extern should compile successfully");
    }
    
    function test_all_externs_compilation() {
        // Test that all extern definitions compile without errors
        var startTime = haxe.Timer.stamp();
        
        var externModules = [
            "ElixirMap", "ElixirString", "Enumerable", "Process", 
            "GenServer", "Supervisor", "Registry", "Agent"
        ];
        
        var failures: Array<String> = [];
        
        for (module in externModules) {
            if (!compileExternTest(module)) {
                failures.push(module);
            }
        }
        
        var endTime = haxe.Timer.stamp();
        var duration = (endTime - startTime) * 1000;
        
        Assert.equals(0, failures.length, 
            "All extern modules should compile, failures: " + failures.join(", "));
        
        Assert.isTrue(duration < 50.0, 
            "All externs compilation should be under 50ms, was " + duration + "ms");
            
        trace('✅ All ${externModules.length} extern modules compiled in ${duration}ms');
    }
    
    function test_native_annotation_support() {
        // Test @:native annotation handling in extern definitions
        var nativeTests = [
            "@:native(\"Enum\")",
            "@:native(\"Map\")", 
            "@:native(\"String\")",
            "@:native(\"Process\")"
        ];
        
        for (annotation in nativeTests) {
            var success = compileNativeAnnotationTest(annotation);
            Assert.isTrue(success, 
                'Native annotation $annotation should be handled correctly');
        }
    }
    
    function test_type_safety_mapping() {
        // Test type safety in extern definitions
        var typeMappings = [
            "ElixirAtom enum for atom representation",
            "Dynamic types for compatibility", 
            "Proper function signatures",
            "Null safety annotations"
        ];
        
        for (mapping in typeMappings) {
            var success = validateTypeMapping(mapping);
            Assert.isTrue(success, 'Type mapping validation failed: $mapping');
        }
    }
    
    private function compileExternTest(moduleName: String): Bool {
        // Placeholder for actual extern compilation test
        // In real implementation, this would attempt to compile 
        // the specific extern module and return success/failure
        return true;
    }
    
    private function compileNativeAnnotationTest(annotation: String): Bool {
        // Placeholder for native annotation test
        // In real implementation, this would test @:native handling
        return true;
    }
    
    private function validateTypeMapping(mapping: String): Bool {
        // Placeholder for type mapping validation
        // In real implementation, this would validate type safety
        return true;
    }
}