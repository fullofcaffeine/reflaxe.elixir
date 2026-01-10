package reflaxe.elixir.preprocessors;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.data.ClassFuncData;

// Import both BasePreprocessor and BaseCompiler with full paths
import reflaxe.preprocessors.BasePreprocessor;
import reflaxe.BaseCompiler;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.TypedExprHelper;

/**
 * FixVariableUsageDetection: Enhanced variable usage detection preprocessor
 * 
 * WHY: The default MarkUnusedVariablesImpl only detects TLocal expressions as variable usage,
 * missing cases where variables are used as objects in method calls (e.g., params.set()).
 * This causes variables to be incorrectly marked as unused with -reflaxe.unused metadata,
 * leading to underscore prefixes that break the generated code.
 * 
 * WHAT: Enhanced preprocessor that properly detects all variable usages including:
 * - Direct variable references (TLocal)
 * - Variables used as objects in method calls (TField with TLocal base)
 * - Variables passed as function arguments
 * - Variables in any expression context
 * 
 * HOW: Runs BEFORE MarkUnusedVariables to remove incorrect -reflaxe.unused metadata
 * from variables that are actually used. Uses comprehensive AST traversal to detect
 * all forms of variable usage, not just TLocal expressions.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on fixing variable usage detection
 * - Open/Closed: Extends preprocessor system without modifying core Reflaxe
 * - Testability: Can be tested independently with specific AST patterns
 * - Maintainability: Clear separation from other preprocessor concerns
 * 
 * EDGE CASES:
 * - Variables used only in method call objects (params.set)
 * - Variables in nested expressions
 * - Variables passed to functions like Map.put
 * - Variables referenced in lambda expressions
 * 
 * NOTE: Extends BasePreprocessor and works around Reflaxe's incomplete type import
 * by explicitly importing BaseCompiler at the package level.
 */
	@:nullSafety(Off)
	class FixVariableUsageDetection extends BasePreprocessor {
		var usedVars: Map<Int, Bool> = new Map();
		var fixedCount: Int = 0;
		
		public function new() {
			// Initialize the preprocessor
		}
	
	/**
	 * Process the class function data to fix variable usage detection
		 * This method implements BasePreprocessor's abstract method.
		 */
		public function process(data: ClassFuncData, compiler: BaseCompiler): Void {
			// Get the expression list from the data
			var list = data.expr.unwrapBlock();
		
		// Reset state
		usedVars = new Map();
		fixedCount = 0;
		
		// First pass: collect all variable declarations and usage
		for(e in list) {
			scanForUsage(e);
		}
		
		// Second pass: remove -reflaxe.unused from actually used variables
			for(e in list) {
				fixMetadata(e);
			}
			
			// No need to modify the data since we're modifying metadata in place
		}
	
	/**
	 * Scan AST for all variable usages, including those in method call objects
	 */
	function scanForUsage(te: TypedExpr) {
			switch(te.expr) {
				case TLocal(tvar):
					// Direct variable reference
					usedVars.set(tvar.id, true);
					
				case TField(obj, field):
					// Check if the object is a local variable (e.g., params.set)
					switch(obj.expr) {
						case TLocal(tvar):
							usedVars.set(tvar.id, true);
							
						case _:
							scanForUsage(obj);
					}
				
			case TCall(e, args):
				// Check function and all arguments for variable usage
				scanForUsage(e);
				for(arg in args) {
					scanForUsage(arg);
				}
				return; // Don't double-iterate
				
			case _:
		}
		
		// Recursively check all sub-expressions
		haxe.macro.TypedExprTools.iter(te, scanForUsage);
	}
	
	/**
	 * Remove -reflaxe.unused metadata from variables that are actually used
	 */
		function fixMetadata(te: TypedExpr) {
			switch(te.expr) {
				case TVar(tvar, maybeExpr):
					if(usedVars.exists(tvar.id) && usedVars.get(tvar.id)) {
						if(tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
							tvar.meta.remove("-reflaxe.unused");
							fixedCount++;
						}
					}
					
					// Process initialization expression if present
					if(maybeExpr != null) {
					fixMetadata(maybeExpr);
				}
				return; // Don't double-iterate
				
			case _:
		}
		
		// Recursively process all sub-expressions
		haxe.macro.TypedExprTools.iter(te, fixMetadata);
	}
}

#end
