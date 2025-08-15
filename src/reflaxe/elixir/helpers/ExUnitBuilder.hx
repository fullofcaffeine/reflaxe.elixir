package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Build macro for ExUnit test classes.
 * 
 * This macro processes classes marked with @:exunit and prepares them
 * for compilation to ExUnit test modules. It handles:
 * 
 * - Registering the class as a test class
 * - Processing @:test and @:describe annotations
 * - Setting up proper metadata for the compiler
 */
class ExUnitBuilder {
    /**
     * Main build macro entry point.
     * Called on classes that extend TestCase.
     */
    public static function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var classType = Context.getLocalClass().get();
        
        // Check if this class should be treated as an ExUnit test
        if (!hasExUnitMeta(classType)) {
            return fields;
        }
        
        // Mark this class for ExUnit compilation
        classType.meta.add(":exunit_test", [], Context.currentPos());
        
        // Process all fields for test annotations
        for (field in fields) {
            processField(field);
        }
        
        // Add test helper imports if needed
        addTestHelperImports(fields);
        
        return fields;
    }
    
    /**
     * Check if a class has @:exunit metadata or extends TestCase
     */
    static function hasExUnitMeta(classType: ClassType): Bool {
        // Check for explicit @:exunit annotation
        if (classType.meta.has(":exunit")) {
            return true;
        }
        
        // Check if extends TestCase
        var current = classType;
        while (current != null) {
            if (current.name == "TestCase" && current.pack.join(".") == "haxe.test") {
                return true;
            }
            current = current.superClass?.t.get();
        }
        
        return false;
    }
    
    /**
     * Process a field to handle test annotations
     */
    static function processField(field: Field): Void {
        switch (field.kind) {
            case FFun(func):
                processTestMethod(field, func);
            case _:
                // Skip non-function fields
        }
    }
    
    /**
     * Process a method that might be a test
     */
    static function processTestMethod(field: Field, func: Function): Void {
        var hasTestMeta = false;
        var testName: String = null;
        
        // Check for @:test annotation
        for (meta in field.meta) {
            if (meta.name == ":test") {
                hasTestMeta = true;
                
                // Extract test name from annotation if provided
                if (meta.params != null && meta.params.length > 0) {
                    switch (meta.params[0].expr) {
                        case EConst(CString(s, _)):
                            testName = s;
                        case _:
                            Context.error("@:test annotation expects string parameter", meta.pos);
                    }
                } else {
                    // Use method name, convert camelCase to readable
                    testName = camelCaseToReadable(field.name);
                }
                break;
            }
        }
        
        if (hasTestMeta) {
            // Add metadata for the compiler
            field.meta.push({
                name: ":exunit_test_method",
                params: [macro $v{testName}],
                pos: field.pos
            });
        }
        
        // Check for @:describe annotation on the class containing this method
        // This will be handled at the class level
    }
    
    /**
     * Convert camelCase method names to readable test names
     */
    static function camelCaseToReadable(name: String): String {
        // Remove "test" prefix if present
        if (name.indexOf("test") == 0) {
            name = name.substr(4);
        }
        
        // Convert camelCase to space-separated words
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char >= "A" && char <= "Z") {
                result += " " + char.toLowerCase();
            } else if (i == 0) {
                result += char.toLowerCase();
            } else {
                result += char;
            }
        }
        
        return result;
    }
    
    /**
     * Add necessary imports for test helper functions
     */
    static function addTestHelperImports(fields: Array<Field>): Void {
        // This will be handled by the compiler when generating the ExUnit module
        // For now, just mark that imports are needed
        Context.getLocalClass().get().meta.add(":needs_test_imports", [], Context.currentPos());
    }
}
#end