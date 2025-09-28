package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.ECondClause;
import reflaxe.elixir.ast.ElixirAST.GuardBranch;       // Use from ElixirAST
import reflaxe.elixir.ast.ElixirAST.ValidationResult;  // Use from ElixirAST
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.naming.ElixirAtom;
import haxe.ds.StringMap;

/**
 * GuardConditionFlattener: Three-phase system for flattening nested guard conditions
 * 
 * WHY: Multiple guard conditions on the same pattern in Haxe switch statements need to be
 * transformed into idiomatic Elixir cond expressions. The current implementation only extracts
 * the first guard, leaving others nested with undefined variables (r2=nil, g2=nil).
 * 
 * WHAT: Provides a complete three-phase transformation pipeline:
 * - Collection: Recursively gather ALL guard conditions from nested if-else chains
 * - Validation: Ensure conditions can be grouped together
 * - Reconstruction: Build flat cond expressions with proper variable scope
 * 
 * HOW: Each phase operates independently with clear interfaces:
 * - GuardConditionCollector performs deep recursive collection
 * - GuardGroupValidator ensures conditions are groupable
 * - GuardConditionReconstructor builds the final flat cond
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each class has one clear purpose
 * - Open/Closed Principle: Easy to extend without modification
 * - Testability: Each phase can be tested independently
 * - Maintainability: Clear separation of concerns
 * 
 * EDGE CASES:
 * - Deep nesting (5+ levels)
 * - Mixed pattern types (RGB vs HSL)
 * - Nil assignments (r2=nil patterns)
 * - Variable shadowing
 */
@:nullSafety(Off)
class GuardConditionFlattener {
	// Empty class to hold the three phase classes
}

/**
 * GuardConditionCollector: Phase 1 - Deep recursive collection of all guard conditions
 * 
 * WHY: Current extraction only gets the first guard condition, missing nested ones
 * WHAT: Recursively collects ALL conditions regardless of nesting depth
 * HOW: Depth-first traversal with automatic unwrapping of wrapper nodes
 */
@:nullSafety(Off)
class GuardConditionCollector {
	
	/**
	 * Collect all guard conditions from an AST node
	 * Recursively traverses the entire if-else tree
	 */
	public static function collectAllGuardConditions(ast: ElixirAST): Array<GuardBranch> {
		var branches: Array<GuardBranch> = [];
		var visitedNodes = new StringMap<Bool>(); // Prevent cycles
		
		function collectRecursive(node: ElixirAST, depth: Int = 0): Void {
			if (node == null) return;
			
			// Create node ID for cycle detection
			var nodeId = Std.string(node.pos) + "_" + Type.enumConstructor(node.def);
			if (visitedNodes.exists(nodeId)) return;
			visitedNodes.set(nodeId, true);
			
			#if debug_guard_flattening
			trace('[GuardCollector] Depth $depth, examining: ${Type.enumConstructor(node.def)}');
			#end
			
			// Unwrap all wrapper nodes first
			var unwrapped = unwrapNode(node);
			if (unwrapped == null) return;
			
			switch(unwrapped.def) {
				case EIf(condition, thenBranch, elseBranch):
					// Found a guard condition
					branches.push({
						pattern: null, // Will be set from the case clause pattern
						guard: condition,
						body: thenBranch,
						depth: depth
					});
					
					#if debug_guard_flattening
					trace('[GuardCollector] Found guard at depth $depth');
					#end
					
					// Continue collecting from else branch
					if (elseBranch != null) {
						collectRecursive(elseBranch, depth + 1);
					}
					
				case ECond(condBranches):
					// Already a cond - extract its branches but look for nested conditions
					for (branch in condBranches) {
						// Check if this is a true -> branch that might contain more conditions
						var isTrueBranch = switch(branch.condition.def) {
							case EBoolean(true): true;
							case EAtom(a): (a:String) == "true";  // Legacy support
							default: false;
						};
						
						if (isTrueBranch) {
							// Look for nested conditions in the true branch
							collectRecursive(branch.body, depth + 1);
						} else {
							branches.push({
								pattern: null, // ECond branches don't have patterns
								guard: branch.condition,
								body: branch.body,
								depth: depth
							});
						}
					}
					
				default:
					// Terminal node - this might be the default case
					if (depth > 0 && !isNilAssignmentBlock(unwrapped)) {
						branches.push({
							pattern: null,
							guard: makeAST(EBoolean(true)),
							body: unwrapped,
							depth: depth
						});
						
						#if debug_guard_flattening
						trace('[GuardCollector] Found default case at depth $depth');
						#end
					}
			}
		}
		
		collectRecursive(ast, 0);
		
		#if debug_guard_flattening
		trace('[GuardCollector] Collected ${branches.length} branches total');
		#end
		
		return branches;
	}
	
	/**
	 * Recursively unwrap wrapper nodes (blocks, parens, nil assignments)
	 */
	static function unwrapNode(node: ElixirAST): ElixirAST {
		if (node == null) return null;
		
		return switch(node.def) {
			case EParen(inner):
				unwrapNode(inner);
				
			case EBlock(exprs):
				// Filter nil assignments and unwrap single expressions
				var cleaned = exprs.filter(e -> !isNilAssignment(e));
				if (cleaned.length == 1) {
					unwrapNode(cleaned[0]);
				} else if (cleaned.length == 0) {
					null;
				} else {
					makeAST(EBlock(cleaned), node.pos);
				}
				
			default:
				node;
		};
	}
	
	/**
	 * Check if an expression is a nil assignment to a generated variable
	 */
	static function isNilAssignment(expr: ElixirAST): Bool {
		if (expr == null) return false;
		
		return switch(expr.def) {
			case EMatch(PVar(name), value):
				// Check for generated variable pattern (r2, g3, etc.)
				~/^[a-z]+\d+$/.match(name) && isNilValue(value);
			default:
				false;
		};
	}
	
	/**
	 * Check if a block only contains nil assignments
	 */
	static function isNilAssignmentBlock(ast: ElixirAST): Bool {
		if (ast == null) return false;
		
		return switch(ast.def) {
			case EBlock(exprs):
				exprs.length > 0 && exprs.filter(e -> !isNilAssignment(e)).length == 0;
			default:
				false;
		};
	}
	
	/**
	 * Check if a value is nil
	 */
	static function isNilValue(ast: ElixirAST): Bool {
		return ast != null && switch(ast.def) {
			case EAtom(a): (a:String) == "nil";
			case ENil: true;
			default: false;
		};
	}
	
	/**
	 * Convert a pattern to a string representation for grouping
	 */
	public static function patternToString(pattern: EPattern): String {
		return switch(pattern) {
			case PVar(name):
				name;
			case PLiteral(value):
				Std.string(value);
			case PTuple(elements):
				var elementStrs = elements.map(p -> patternToString(p));
				'{${elementStrs.join(", ")}}';
			case PList(elements):
				var elementStrs = elements.map(p -> patternToString(p));
				'[${elementStrs.join(", ")}]';
			case PCons(head, tail):
				'[${patternToString(head)} | ${patternToString(tail)}]';
			case PMap(pairs):
				"%{map}";
			case PStruct(module, fields):
				'%$module{}';
			case PPin(pattern):
				'^${patternToString(pattern)}';
			case PWildcard:
				"_";
			case PAlias(varName, pattern):
				'$varName = ${patternToString(pattern)}';
			case PBinary(segments):
				"<<binary>>";
		};
	}
	
	/**
	 * Extract variables used in an expression
	 */
	public static function extractUsedVariables(expr: ElixirAST): Array<String> {
		var vars = [];
		
		function collect(node: ElixirAST): Void {
			if (node == null) return;
			
			switch(node.def) {
				case EVar(name):
					// Skip generated variables
					if (!~/^[a-z]+\d+$/.match(name)) {
						vars.push(name);
					}
				case EBinary(op, left, right):
					collect(left);
					collect(right);
				case ECall(target, method, args):
					collect(target);
					for (arg in args) collect(arg);
				case EParen(inner):
					collect(inner);
				case EUnary(op, expr):
					collect(expr);
				default:
					// Continue traversal for other node types
			}
		}
		
		collect(expr);
		return vars;
	}
	
	/**
	 * Helper to create AST nodes
	 */
	static function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
		return {def: def, pos: pos != null ? pos : haxe.macro.Context.currentPos(), metadata: null};
	}
}

/**
 * GuardGroupValidator: Phase 2 - Validates guard branches can be grouped together
 * 
 * WHY: Not all conditions should be grouped - need to validate compatibility
 * WHAT: Ensures conditions operate on same variables and patterns
 * HOW: Analyzes variable usage and pattern compatibility
 */
@:nullSafety(Off)
class GuardGroupValidator {
	
	/**
	 * Validate if guard branches can be grouped together
	 */
	public static function validateGuardGroup(
		branches: Array<GuardBranch>, 
		boundVars: Array<String>
	): ValidationResult {
		
		var result: ValidationResult = {
			canGroup: true,
			reason: "Valid for grouping",
			groupKey: "",
			patterns: []
		};
		
		if (branches.length == 0) {
			result.canGroup = false;
			result.reason = "No branches to group";
			return result;
		}
		
		#if debug_guard_flattening
		trace('[GuardValidator] Validating ${branches.length} branches with bound vars: $boundVars');
		#end
		
		// Analyze branches for groupability
		var boundVarSet = new StringMap<Bool>();
		for (v in boundVars) boundVarSet.set(v, true);
		
		// Track patterns found
		var patternsFound: Array<String> = [];
		
		for (branch in branches) {
			// Collect pattern info
			if (branch.pattern != null) {
				var patternStr = GuardConditionCollector.patternToString(branch.pattern);
				if (patternsFound.indexOf(patternStr) == -1) {
					patternsFound.push(patternStr);
				}
			}
			
			// Check for external variable usage
			var usedVars = GuardConditionCollector.extractUsedVariables(branch.guard);
			for (v in usedVars) {
				if (!boundVarSet.exists(v)) {
					// Check if it's a modified version of a bound var (r2 -> r)
					var baseName = ~/^([a-z]+)\d+$/.replace(v, "$1");
					if (!boundVarSet.exists(baseName)) {
						result.canGroup = false;
						result.reason = 'Branch uses external variable: $v';
						break;
					}
				}
			}
		}
		
		// Update result with collected patterns
		result.patterns = patternsFound;
		if (patternsFound.length > 0) {
			result.groupKey = patternsFound[0]; // Use first pattern as key
		}
		
		#if debug_guard_flattening
		trace('[GuardValidator] Can group: ${result.canGroup}, reason: ${result.reason}');
		trace('[GuardValidator] Patterns found: ${patternsFound}');
		#end
		
		return result;
	}
}

/**
 * GuardConditionReconstructor: Phase 3 - Builds flat cond from validated branches
 * 
 * WHY: Need to create idiomatic Elixir cond expression from collected guards
 * WHAT: Transforms validated guard branches into single cond expression
 * HOW: Builds cond branches while fixing variable references
 */
@:nullSafety(Off)
class GuardConditionReconstructor {
	
	/**
	 * Build a flat cond expression from validated guard branches
	 */
	public static function buildFlatCond(
		branches: Array<GuardBranch>,
		boundVars: Array<String>,
		originalPattern: EPattern
	): ElixirAST {
		
		if (branches.length == 0) return null;
		
		#if debug_guard_flattening
		trace('[GuardReconstructor] Building cond from ${branches.length} branches');
		#end
		
		// Build cond branches with variable fixing
		var condBranches: Array<ECondClause> = [];
		
		for (branch in branches) {
			// Fix variable references in guard condition
			var fixedCondition = fixVariableReferences(
				branch.guard, 
				boundVars
			);
			
			// Fix variable references in body
			var fixedBody = fixVariableReferences(
				branch.body,
				boundVars
			);
			
			condBranches.push({
				condition: fixedCondition,
				body: fixedBody
			});
			
			#if debug_guard_flattening
			var condStr = ElixirASTPrinter.printAST(fixedCondition);
			trace('[GuardReconstructor] Added condition: $condStr');
			#end
		}
		
		// Ensure we have a default branch
		var hasDefault = false;
		if (condBranches.length > 0) {
			var lastBranch = condBranches[condBranches.length - 1];
			hasDefault = switch(lastBranch.condition.def) {
				case EBoolean(true): true;
				case EAtom(a): (a:String) == "true";  // Legacy support
				default: false;
			};
		}
		
		if (!hasDefault) {
			// Add explicit true branch with nil
			condBranches.push({
				condition: makeAST(EBoolean(true)),
				body: makeAST(ENil)
			});
			
			#if debug_guard_flattening
			trace('[GuardReconstructor] Added default true -> nil branch');
			#end
		}
		
		var result = makeAST(ECond(condBranches));
		
		#if debug_guard_flattening
		trace('[GuardReconstructor] Built cond with ${condBranches.length} branches');
		#end
		
		return result;
	}
	
	/**
	 * Fix variable references that may have been renamed during compilation
	 */
	public static function fixVariableReferences(
		expr: ElixirAST,
		boundVars: Array<String>
	): ElixirAST {
		
		if (expr == null) return null;
		
		// Map of generated names to original names
		var varMap = buildVariableMap(boundVars);
		
		return transformAST(expr, function(node) {
			switch(node.def) {
				case EVar(name):
					// Check if this is a generated variable name
					if (~/^[a-z]+\d+$/.match(name)) {
						// Extract base name (r2 -> r, g3 -> g)
						var baseName = ~/^([a-z]+)\d+$/.replace(name, "$1");
						if (varMap.exists(baseName)) {
							#if debug_guard_flattening
							trace('[GuardReconstructor] Fixing variable $name -> $baseName');
							#end
							return makeAST(EVar(baseName), node.pos);
						}
					}
					return node;
				default:
					return node;
			}
		});
	}
	
	/**
	 * Build a map of variable names for fixing references
	 */
	static function buildVariableMap(boundVars: Array<String>): StringMap<String> {
		var map = new StringMap<String>();
		
		for (v in boundVars) {
			map.set(v, v); // Identity mapping for bound vars
		}
		
		return map;
	}
	
	/**
	 * Transform AST recursively
	 */
	static function transformAST(ast: ElixirAST, transformer: ElixirAST -> ElixirAST): ElixirAST {
		if (ast == null) return null;
		
		// First transform children
		var transformed = switch(ast.def) {
			case EBinary(op, left, right):
				makeAST(EBinary(op, 
					transformAST(left, transformer),
					transformAST(right, transformer)
				), ast.pos);
				
			case EUnary(op, expr):
				makeAST(EUnary(op, transformAST(expr, transformer)), ast.pos);
				
			case EParen(inner):
				makeAST(EParen(transformAST(inner, transformer)), ast.pos);
				
			case ECall(target, method, args):
				makeAST(ECall(
					transformAST(target, transformer),
					method,
					args.map(a -> transformAST(a, transformer))
				), ast.pos);
				
			case EBlock(exprs):
				makeAST(EBlock(exprs.map(e -> transformAST(e, transformer))), ast.pos);
				
			case EIf(cond, thenBranch, elseBranch):
				makeAST(EIf(
					transformAST(cond, transformer),
					transformAST(thenBranch, transformer),
					elseBranch != null ? transformAST(elseBranch, transformer) : null
				), ast.pos);
				
			default:
				ast;
		};
		
		// Then apply the transformer
		return transformer(transformed);
	}
	
	/**
	 * Helper to create AST nodes
	 */
	static function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
		return {def: def, pos: pos != null ? pos : haxe.macro.Context.currentPos(), metadata: null};
	}
}