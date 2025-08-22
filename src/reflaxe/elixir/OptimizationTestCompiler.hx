package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.ReflectCompiler;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.TypedExprHelper;

/**
 * Experimental compiler to test optimization pipeline differences
 * 
 * This compiler logs TypedExpr at both onAfterTyping and onGenerate
 * to demonstrate what optimizations Haxe performs between these phases.
 */
class OptimizationTestCompiler {
    static var afterTypingAST: String = "";
    static var onGenerateAST: String = "";
    
    /**
     * Initialize the optimization test compiler
     */
    public static function Start() {
        Context.onAfterInitMacros(Begin);
    }
    
    /**
     * Begin compiler registration with dual-phase logging
     */
    public static function Begin() {
        #if (haxe >= version("5.0.0"))
        switch(Context.getConfiguration().platform) {
            case CustomTarget("elixir"):
            case _: 
                return;
        }
        #end
        
        // Hook into onAfterTyping to capture unoptimized AST
        Context.onAfterTyping(function(moduleTypes: Array<ModuleType>) {
            trace("\n========== onAfterTyping Phase (BEFORE optimization) ==========");
            
            for (mt in moduleTypes) {
                switch(mt) {
                    case TClassDecl(c):
                        var classType = c.get();
                        if (classType.name == "Main") {
                            trace('Class: ${classType.name}');
                            for (field in classType.statics.get()) {
                                if (field.name == "main") {
                                    trace('  Analyzing main() function...');
                                    switch(field.expr()) {
                                        case null:
                                            trace('    No expression');
                                        case {expr: TFunction(func)}:
                                            trace('    Function body analysis:');
                                            analyzeExpression(func.expr, 2);
                                        case _:
                                            trace('    Not a function');
                                    }
                                }
                            }
                        }
                    case _:
                }
            }
        });
        
        // Hook into onGenerate to capture optimized AST
        Context.onGenerate(function(types: Array<Type>) {
            trace("\n========== onGenerate Phase (AFTER optimization) ==========");
            
            for (t in types) {
                switch(t) {
                    case TInst(c, _):
                        var classType = c.get();
                        if (classType.name == "Main") {
                            trace('Class: ${classType.name}');
                            for (field in classType.statics.get()) {
                                if (field.name == "main") {
                                    trace('  Analyzing main() function...');
                                    switch(field.expr()) {
                                        case null:
                                            trace('    No expression');
                                        case {expr: TFunction(func)}:
                                            trace('    Function body analysis:');
                                            analyzeExpression(func.expr, 2);
                                        case _:
                                            trace('    Not a function');
                                    }
                                }
                            }
                        }
                    case _:
                }
            }
            
            trace("\n========== OPTIMIZATION SUMMARY ==========");
            trace("Key observations about what changed between phases:");
            trace("- Check for eliminated dead code");
            trace("- Look for removed unused variables");
            trace("- Notice inlined temporary variables");
            trace("- Observe eliminated constant conditions");
        });
        
        // Still register the normal compiler for actual compilation
        ReflectCompiler.AddCompiler(new ElixirCompiler(), {
            fileOutputExtension: ".ex",
            outputDirDefineName: "elixir_output",
            fileOutputType: FilePerModule,
            ignoreTypes: [],
            targetCodeInjectionName: "__elixir__",
            ignoreBodilessFunctions: false
        });
    }
    
    /**
     * Analyze and log expression structure
     */
    static function analyzeExpression(expr: TypedExpr, indent: Int): Void {
        if (expr == null) return;
        
        var prefix = StringTools.lpad("", "  ", indent);
        
        switch(expr.expr) {
            case TBlock(exprs):
                trace('${prefix}TBlock with ${exprs.length} expressions');
                for (e in exprs) {
                    analyzeExpression(e, indent + 1);
                }
                
            case TVar(v, init):
                trace('${prefix}TVar: ${v.name} (used: ${isVariableUsed(v) ? "yes" : "no"})');
                if (init != null) {
                    analyzeExpression(init, indent + 1);
                }
                
            case TSwitch(e, cases, def):
                trace('${prefix}TSwitch with ${cases.length} cases');
                for (c in cases) {
                    trace('${prefix}  Case with ${c.values.length} patterns');
                    if (hasUnusedEnumParameters(c)) {
                        trace('${prefix}    ⚠️ ORPHANED ENUM PARAMETERS DETECTED');
                    }
                }
                
            case TIf(cond, e1, e2):
                switch(cond.expr) {
                    case TConst(TBool(true)):
                        trace('${prefix}TIf with constant TRUE condition (dead else branch)');
                    case TConst(TBool(false)):
                        trace('${prefix}TIf with constant FALSE condition (dead then branch)');
                    case _:
                        trace('${prefix}TIf with dynamic condition');
                }
                
            case TLocal(v):
                trace('${prefix}TLocal: ${v.name}');
                
            case TEnumParameter(e, ef, index):
                trace('${prefix}TEnumParameter: ${ef.name} index ${index} (POTENTIAL ORPHAN)');
                
            case TReturn(e):
                trace('${prefix}TReturn');
                if (e != null) analyzeExpression(e, indent + 1);
                
            case _:
                trace('${prefix}${expr.expr.getName()}');
        }
    }
    
    /**
     * Check if a variable is used (simplified check)
     */
    static function isVariableUsed(v: TVar): Bool {
        // In real implementation, would traverse AST to check usage
        // For now, just check if it starts with "unused"
        return !StringTools.startsWith(v.name, "unused");
    }
    
    /**
     * Check if switch case has unused enum parameters
     */
    static function hasUnusedEnumParameters(c: {values: Array<TypedExpr>, expr: TypedExpr}): Bool {
        // Simplified check - in reality would analyze if extracted parameters are used
        for (v in c.values) {
            switch(v.expr) {
                case TEnumParameter(_, _, _):
                    // Check if the case body is effectively empty
                    switch(c.expr.expr) {
                        case TBlock([]): return true;
                        case TConst(_): return true; // Just a constant
                        case _:
                    }
                case _:
            }
        }
        return false;
    }
}

#end