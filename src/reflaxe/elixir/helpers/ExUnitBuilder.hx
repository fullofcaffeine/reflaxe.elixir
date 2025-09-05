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
        var hasSetup = false;
        var hasSetupAll = false;
        var hasTeardown = false;
        var hasTeardownAll = false;
        var describeBlock: String = null;
        var isAsync = false;
        var tags: Array<String> = [];
        
        if (field.meta != null) {
            for (meta in field.meta) {
                if (meta.name == ":test" || meta.name == "test") {
                    hasTest = true;
                } else if (meta.name == ":setup" || meta.name == "setup") {
                    hasSetup = true;
                } else if (meta.name == ":setupAll" || meta.name == "setupAll") {
                    hasSetupAll = true;
                } else if (meta.name == ":teardown" || meta.name == "teardown") {
                    hasTeardown = true;
                } else if (meta.name == ":teardownAll" || meta.name == "teardownAll") {
                    hasTeardownAll = true;
                } else if (meta.name == ":describe" || meta.name == "describe") {
                    // Extract describe block name from metadata params
                    if (meta.params != null && meta.params.length > 0) {
                        switch(meta.params[0].expr) {
                            case EConst(CString(s)): describeBlock = s;
                            default:
                        }
                    }
                } else if (meta.name == ":async" || meta.name == "async") {
                    isAsync = true;
                } else if (meta.name == ":tag" || meta.name == "tag") {
                    // Extract tag value from metadata params
                    if (meta.params != null && meta.params.length > 0) {
                        switch(meta.params[0].expr) {
                            case EConst(CString(s)): tags.push(s);
                            default:
                        }
                    }
                }
            }
        }
        
        if (hasTest) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:test on method: ${field.name}');
            if (describeBlock != null) {
                trace('[XRay ExUnit]   - In describe block: ${describeBlock}');
            }
            if (isAsync) {
                trace('[XRay ExUnit]   - Async test');
            }
            if (tags.length > 0) {
                trace('[XRay ExUnit]   - Tags: ${tags.join(", ")}');
            }
            #end
            
            // Add metadata to help the compiler generate proper ExUnit test
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.test",
                params: [],
                pos: field.pos
            });
            
            // Add describe block metadata if present
            if (describeBlock != null) {
                field.meta.push({
                    name: ":elixir.describe",
                    params: [{expr: EConst(CString(describeBlock)), pos: field.pos}],
                    pos: field.pos
                });
            }
            
            // Add async metadata if present
            if (isAsync) {
                field.meta.push({
                    name: ":elixir.async",
                    params: [],
                    pos: field.pos
                });
            }
            
            // Add tag metadata if present
            for (tag in tags) {
                field.meta.push({
                    name: ":elixir.tag",
                    params: [{expr: EConst(CString(tag)), pos: field.pos}],
                    pos: field.pos
                });
            }
        }
        
        if (hasSetup) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:setup on method: ${field.name}');
            #end
            
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.setup",
                params: [],
                pos: field.pos
            });
        }
        
        if (hasSetupAll) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:setupAll on method: ${field.name}');
            #end
            
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.setupAll",
                params: [],
                pos: field.pos
            });
        }
        
        if (hasTeardown) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:teardown on method: ${field.name}');
            #end
            
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.teardown",
                params: [],
                pos: field.pos
            });
        }
        
        if (hasTeardownAll) {
            #if debug_exunit
            trace('[XRay ExUnit] ✓ Found @:teardownAll on method: ${field.name}');
            #end
            
            if (field.meta == null) field.meta = [];
            field.meta.push({
                name: ":elixir.teardownAll",
                params: [],
                pos: field.pos
            });
        }
        
        // Also check for setup/teardown methods by name (for backward compatibility)
        if (!hasSetup && !hasSetupAll && !hasTeardown && !hasTeardownAll) {
            switch (field.name) {
                case "setup":
                    if (field.meta == null) field.meta = [];
                    field.meta.push({
                        name: ":elixir.setup",
                        params: [],
                        pos: field.pos
                    });
                case "setupAll":
                    if (field.meta == null) field.meta = [];
                    field.meta.push({
                        name: ":elixir.setupAll",
                        params: [],
                        pos: field.pos
                    });
                case "teardown":
                    if (field.meta == null) field.meta = [];
                    field.meta.push({
                        name: ":elixir.teardown",
                        params: [],
                        pos: field.pos
                    });
                case "teardownAll":
                    if (field.meta == null) field.meta = [];
                    field.meta.push({
                        name: ":elixir.teardownAll",
                        params: [],
                        pos: field.pos
                    });
            }
        }
    }
}
#end