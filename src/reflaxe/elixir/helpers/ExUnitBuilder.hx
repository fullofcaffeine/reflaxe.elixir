package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ExUnitBuilder: Build macro for ExUnit test cases
 * 
 * WHY: Enable writing ExUnit tests in Haxe with @:exunit and @:test metadata,
 * providing a seamless testing experience that compiles to idiomatic ExUnit tests.
 * 
 * WHAT: Transforms classes marked with @:exunit into proper ExUnit test modules
 * - Processes @:test metadata on methods to generate test blocks
 * - Handles setup/teardown lifecycle methods
 * - Ensures proper ExUnit module structure in generated Elixir
 * 
 * HOW: Uses Haxe's build macro system to:
 * 1. Identify test methods marked with @:test
 * 2. Transform test methods into ExUnit-compatible format
 * 3. Add necessary ExUnit metadata for the compiler to generate proper Elixir
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles ExUnit test transformation
 * - Open/Closed: New test features can be added without modifying existing code
 * - Testability: Each test compiles to a standalone ExUnit module
 * - Maintainability: Clear separation between test definition and compilation
 * 
 * EDGE CASES:
 * - Classes without @:exunit are not processed
 * - Methods without @:test are treated as helper methods
 * - Setup/teardown methods are optional
 */
class ExUnitBuilder {
    /**
     * Build macro entry point for @:autoBuild
     * 
     * WHY: Called by Haxe when building classes that extend TestCase
     * WHAT: Transforms the class into an ExUnit-compatible structure
     * HOW: Analyzes fields and adds necessary metadata for ExUnit compilation
     * 
     * @return Array of transformed fields
     */
    public static function build(): Array<Field> {
        #if debug_exunit
        trace("[XRay ExUnit] BUILD START");
        #end
        
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        #if debug_exunit
        trace('[XRay ExUnit] Processing class: ${cls.name}');
        trace('[XRay ExUnit] Found ${fields.length} fields');
        #end
        
        // Check if the class has @:exunit metadata
        var hasExUnit = cls.meta.has(":exunit");
        
        if (!hasExUnit) {
            #if debug_exunit
            trace("[XRay ExUnit] No @:exunit metadata, skipping transformation");
            #end
            return fields;
        }
        
        #if debug_exunit
        trace("[XRay ExUnit] ✓ @:exunit metadata found, processing test methods");
        #end
        
        // Process each field to identify and mark test methods
        for (field in fields) {
            processField(field);
        }
        
        // Add ExUnit compilation hint for the Elixir compiler
        cls.meta.add(":elixir.exunit", [], cls.pos);
        
        #if debug_exunit
        trace("[XRay ExUnit] BUILD END - Processed ${fields.length} fields");
        #end
        
        return fields;
    }
    
    /**
     * Process individual field for test metadata
     * 
     * WHY: Each method needs to be analyzed to determine if it's a test
     * WHAT: Identifies @:test methods and marks them for ExUnit compilation
     * HOW: Checks metadata and adds compilation hints
     * 
     * @param field The field to process
     */
    static function processField(field: Field): Void {
        #if debug_exunit
        trace('[XRay ExUnit] Processing field: ${field.name}');
        #end
        
        // Check if this field has @:test metadata
        var hasTest = false;
        if (field.meta != null) {
            for (meta in field.meta) {
                if (meta.name == ":test" || meta.name == "test") {
                    hasTest = true;
                    break;
                }
            }
        }
        
        if (hasTest) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:test on method: ${field.name}');
            #end
            
            // Add metadata to help the compiler generate proper ExUnit test
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.test",
                params: [],
                pos: field.pos
            });
        }
        
        // Check for setup/teardown methods
        switch (field.name) {
            case "setup", "setupAll", "teardown", "teardownAll":
                #if debug_exunit
                trace('[XRay ExUnit] ✓ Found lifecycle method: ${field.name}');
                #end
                
                // Mark as ExUnit lifecycle method
                if (field.meta == null) field.meta = [];
                field.meta.push({
                    name: ':elixir.${field.name}',
                    params: [],
                    pos: field.pos
                });
        }
    }
}
#end