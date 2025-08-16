package reflaxe.js;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.JSGenApi;

using Lambda;

/**
 * Custom JavaScript generator that extends ExampleJSGenerator to support async/await.
 * 
 * This generator adds native JavaScript async function support by detecting @:async
 * metadata on methods and prepending the 'async' keyword to function declarations.
 * 
 * Features:
 * - Generates native 'async function' declarations for @:async methods
 * - Preserves all existing JavaScript generation functionality
 * - Works with await() macro to create proper async/await syntax
 * - 100% compatible with JavaScript Promise specification
 * 
 * Usage:
 * Add to build configuration:
 * --macro haxe.macro.Compiler.setCustomJSGenerator("reflaxe.js.AsyncJSGenerator")
 */
class AsyncJSGenerator extends haxe.macro.ExampleJSGenerator {
    
    /**
     * Constructor - initializes the async-aware JavaScript generator.
     * 
     * @param api JSGenApi instance for JavaScript code generation
     */
    public function new(api: JSGenApi) {
        super(api);
    }
    
    /**
     * Generates a class field (method or property) with async support.
     * 
     * Overrides the base implementation to check for @:async metadata
     * and generate proper async function declarations.
     * 
     * @param c The class type containing the field
     * @param p The path to the class
     * @param f The class field to generate
     */
    override function genClassField(c: ClassType, p: String, f: ClassField) {
        if (isAsyncMethod(f)) {
            genAsyncClassField(c, p, f);
        } else {
            super.genClassField(c, p, f);
        }
    }
    
    /**
     * Generates a static field with async support.
     * 
     * Overrides the base implementation to check for @:async metadata
     * and generate proper async static function declarations.
     * 
     * @param c The class type containing the static field
     * @param p The path to the class
     * @param f The static class field to generate
     */
    override function genStaticField(c: ClassType, p: String, f: ClassField) {
        if (isAsyncMethod(f)) {
            genAsyncStaticField(c, p, f);
        } else {
            super.genStaticField(c, p, f);
        }
    }
    
    /**
     * Checks if a class field has @:jsAsync metadata.
     * 
     * This metadata is added by the Async build macro after processing @:async functions.
     * 
     * @param f The class field to check
     * @return True if the field has @:jsAsync metadata
     */
    function isAsyncMethod(f: ClassField): Bool {
        if (f.meta == null) return false;
        
        return f.meta.has(":jsAsync");
    }
    
    /**
     * Generates an async class field (instance method).
     * 
     * Creates a function declaration with the 'async' keyword prepended.
     * 
     * @param c The class type containing the field
     * @param p The path to the class
     * @param f The async class field to generate
     */
    function genAsyncClassField(c: ClassType, p: String, f: ClassField) {
        checkFieldName(c, f);
        var field = field(f.name);
        var e = f.expr();
        
        if (e == null) {
            // Abstract or interface method
            return;
        }
        
        switch (f.kind) {
            case FMethod(_):
                print('$p.prototype$field = async ');
                genMethodExpr(e);
                newline();
            case FVar(AccResolve, _):
                // Resolve accessor - handle specially
                return;
            case FVar(_, _):
                // Regular field
                super.genClassField(c, p, f);
        }
    }
    
    /**
     * Generates an async static field (static method).
     * 
     * Creates a static function declaration with the 'async' keyword prepended.
     * 
     * @param c The class type containing the static field
     * @param p The path to the class
     * @param f The async static field to generate
     */
    function genAsyncStaticField(c: ClassType, p: String, f: ClassField) {
        checkFieldName(c, f);
        var field = field(f.name);
        var e = f.expr();
        
        if (e == null) {
            // Abstract or interface method
            return;
        }
        
        switch (f.kind) {
            case FMethod(_):
                print('$p$field = async ');
                genMethodExpr(e);
                newline();
            case FVar(_, _):
                // Regular static field
                super.genStaticField(c, p, f);
        }
    }
    
    /**
     * Generates a method expression (function body).
     * 
     * This is a helper method to generate the function part of async methods,
     * working with the prepended 'async' keyword.
     * 
     * @param e The typed expression representing the method
     */
    function genMethodExpr(e: TypedExpr) {
        // Generate the function expression using the API
        // This will create: function(args) { body }
        // Combined with our 'async ' prefix it becomes: async function(args) { body }
        genExpr(e);
    }
    
    /**
     * Main generation method that produces the final JavaScript output.
     * Inherits the full generation pipeline from ExampleJSGenerator and adds async support.
     */
    override public function generate() {
        super.generate();
    }
    
    /**
     * Override the base checkFieldName to use the exact same logic.
     * Checks if a field name conflicts with JavaScript keywords.
     */
    override function checkFieldName(c: ClassType, f: ClassField) {
        super.checkFieldName(c, f);
    }
    
    #if (macro || display)
    /**
     * Static method to register the AsyncJSGenerator.
     * Use this to enable async/await support in Haxe→JavaScript compilation.
     */
    public static function use() {
        haxe.macro.Compiler.setCustomJSGenerator(function(api) new AsyncJSGenerator(api).generate());
    }
    #end
}