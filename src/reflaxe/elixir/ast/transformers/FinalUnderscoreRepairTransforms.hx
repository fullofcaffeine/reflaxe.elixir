package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
#if debug_underscore_repair
import Type;
#end

/**
 * FinalUnderscoreRepairTransforms
 *
 * WHAT
 * - Final pass to fix the "underscored variable is used after being set" warning.
 * - Detects variables that were underscore-prefixed too early but are actually used,
 *   and removes the underscore prefix to make them regular variables.
 *
 * WHY
 * - The compiler applies underscore prefixes at build time (in builders) before full
 *   usage analysis is complete. This causes variables like `_this` to get underscore
 *   prefixes but then be used later, triggering Elixir warnings.
 * - Phase 1.3 of the 1.0 roadmap addresses this by centralizing underscore prefixing.
 * - This pass is a FINAL sentinel that repairs any cases where underscore was applied
 *   to a variable that is actually used.
 *
 * HOW
 * - Scans EBlock and EDo blocks for EMatch assignments where:
 *   1. LHS is EVar with underscore-prefixed name (e.g., `_this`, `_result`)
 *   2. The same variable is used later in the block
 * - When found, rewrites both the assignment and all references to use the
 *   non-underscore name (e.g., `_this` → `this`).
 * - Uses VarUseAnalyzer for proper usage detection including closures and interpolation.
 *
 * EXAMPLES
 * Before:
 *   _this = t.title
 *   String.downcase(_this)
 * After:
 *   this = t.title
 *   String.downcase(this)
 *
 * @see docs/08-roadmap/ - 1.0 Production-Ready Roadmap
 */
class FinalUnderscoreRepairTransforms {
    /**
     * Main transformation pass
     */
    public static function transformPass(ast: ElixirAST): ElixirAST {
        #if debug_underscore_repair
        // DISABLED: trace('[FinalUnderscoreRepair] === PASS INVOKED ===');
        #end
        return ElixirASTTransformer.transformNode(ast, transformNode);
    }

    static function transformNode(n: ElixirAST): ElixirAST {
        #if debug_underscore_repair
        // DISABLED: trace('[UnderscoreRepair] Processing node: ${Type.enumConstructor(n.def)}');
        #end
        return switch (n.def) {
            case EBlock(stmts):
                #if debug_underscore_repair
                // DISABLED: trace('[UnderscoreRepair] EBlock with ${stmts.length} statements');
                for (s in stmts) {
                    if (s != null) trace('[UnderscoreRepair]   - ${Type.enumConstructor(s.def)}');
                }
                #end
                var repaired = repairUnderscoreUsageInBlock(stmts);
                makeASTWithMeta(EBlock(repaired), n.metadata, n.pos);

            case EDo(stmts):
                var repaired = repairUnderscoreUsageInBlock(stmts);
                makeASTWithMeta(EDo(repaired), n.metadata, n.pos);

            case EIf(cond, thenBranch, elseBranch):
                #if debug_underscore_repair
                // DISABLED: trace('[UnderscoreRepair] EIf detected');
                // DISABLED: trace('[UnderscoreRepair]   thenBranch type: ${thenBranch != null ? Type.enumConstructor(thenBranch.def) : "null"}');
                // DISABLED: trace('[UnderscoreRepair]   elseBranch type: ${elseBranch != null ? Type.enumConstructor(elseBranch.def) : "null"}');
                // Show contents of thenBranch if it's a block
                if (thenBranch != null && thenBranch.def != null) {
                    switch (thenBranch.def) {
                        case EBlock(stmts):
                            // DISABLED: trace('[UnderscoreRepair]   thenBranch EBlock has ${stmts.length} stmts');
                            for (ti in 0...stmts.length) {
                                var ts = stmts[ti];
                                if (ts != null && ts.def != null) {
                                    // DISABLED: trace('[UnderscoreRepair]     then[$ti]: ${Type.enumConstructor(ts.def)}');
                                    switch (ts.def) {
                                        case EMatch(pattern, _):
                                            switch (pattern) {
                                                case PVar(vn): trace('[UnderscoreRepair]       PVar: "$vn"');
                                                default:
                                            }
                                        case EBinary(op, lhs, _):
                                            // DISABLED: trace('[UnderscoreRepair]       EBinary op: $op');
                                            if (lhs != null) switch (lhs.def) {
                                                case EVar(vn): trace('[UnderscoreRepair]         LHS EVar: "$vn"');
                                                default:
                                            }
                                        default:
                                    }
                                }
                            }
                        case EDo(stmts):
                            // DISABLED: trace('[UnderscoreRepair]   thenBranch EDo has ${stmts.length} stmts');
                        default:
                    }
                }
                #end
                // Process if branches - these can contain _this patterns
                var repairedThen = transformNode(thenBranch);
                var repairedElse = elseBranch != null ? transformNode(elseBranch) : null;
                makeASTWithMeta(EIf(cond, repairedThen, repairedElse), n.metadata, n.pos);

            case EDef(name, args, guards, body):
                // Process function body
                var repairedBody = transformNode(body);
                makeASTWithMeta(EDef(name, args, guards, repairedBody), n.metadata, n.pos);

            case EDefp(name, args, guards, body):
                var repairedBody = transformNode(body);
                makeASTWithMeta(EDefp(name, args, guards, repairedBody), n.metadata, n.pos);

            case EFn(clauses):
                var repairedClauses = [for (c in clauses) {
                    args: c.args,
                    guard: c.guard,
                    body: transformNode(c.body)
                }];
                makeASTWithMeta(EFn(repairedClauses), n.metadata, n.pos);

            case ECase(expr, clauses):
                // Process case clauses
                var repairedClauses = [for (c in clauses) {
                    pattern: c.pattern,
                    guard: c.guard,
                    body: transformNode(c.body)
                }];
                makeASTWithMeta(ECase(expr, repairedClauses), n.metadata, n.pos);

            case EMatch(pattern, expr):
                // Process the expression side of a match (important for nested structures)
                var repairedExpr = transformNode(expr);
                makeASTWithMeta(EMatch(pattern, repairedExpr), n.metadata, n.pos);

            default:
                n;
        }
    }

    /**
     * Repair underscore usage in a statement block
     *
     * Scans for pattern: `_varname = expr` followed by usage of `_varname`
     * Rewrites to: `varname = expr` and updates all references
     */
    static function repairUnderscoreUsageInBlock(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length == 0) return stmts;

        #if debug_underscore_repair
        // DISABLED: trace('[UnderscoreRepair] repairUnderscoreUsageInBlock called with ${stmts.length} statements');
        for (idx in 0...stmts.length) {
            var s = stmts[idx];
            if (s != null && s.def != null) {
                // DISABLED: trace('[UnderscoreRepair] repairBlock stmt[$idx]: ${Type.enumConstructor(s.def)}');
                // Show more detail for match patterns
                switch (s.def) {
                    case EMatch(pattern, _):
                        // DISABLED: trace('[UnderscoreRepair]   EMatch pattern: ${Type.enumConstructor(pattern)}');
                        switch (pattern) {
                            case PVar(vn): trace('[UnderscoreRepair]     PVar: "$vn"');
                            default:
                        }
                    case EBinary(op, lhs, _):
                        // DISABLED: trace('[UnderscoreRepair]   EBinary op: $op');
                        if (lhs != null && lhs.def != null) {
                            // DISABLED: trace('[UnderscoreRepair]   EBinary lhs: ${Type.enumConstructor(lhs.def)}');
                            switch (lhs.def) {
                                case EVar(vn): trace('[UnderscoreRepair]     EVar: "$vn"');
                                default:
                            }
                        }
                    default:
                }
            }
        }
        #end

        // Collect all underscore-prefixed variables that are used later
        var usedUnderscoreVars = new Map<String, Int>(); // varName -> index of assignment
        var usage = OptimizedVarUseAnalyzer.build(stmts);

        for (i in 0...stmts.length) {
            var stmt = stmts[i];
            if (stmt == null) continue;

            // Check if this is an underscore-prefixed assignment
            // Handle BOTH EMatch(PVar(...), ...) AND EBinary(Match, EVar(...), ...) forms
            switch (stmt.def) {
                case EMatch(pattern, rhsExpr):
                    #if debug_underscore_repair
                    // DISABLED: trace('[UnderscoreRepair] Found EMatch at index $i');
                    // DISABLED: trace('[UnderscoreRepair]   Pattern type: ${Type.enumConstructor(pattern)}');
                    switch (pattern) {
                        case PVar(varName):
                            // DISABLED: trace('[UnderscoreRepair]   PVar name: "$varName"');
                            // DISABLED: trace('[UnderscoreRepair]   isUnderscorePrefixed: ${isUnderscorePrefixedUsableVar(varName)}');
                        default:
                            // DISABLED: trace('[UnderscoreRepair]   Not a PVar pattern');
                    }
                    #end
                    // Only process if it's a PVar with underscore prefix
                    switch (pattern) {
                        case PVar(name) if (isUnderscorePrefixedUsableVar(name)):
                            #if debug_underscore_repair
                            // DISABLED: trace('[UnderscoreRepair] Found underscore var assignment (EMatch): $name at index $i');
                            #end
                            // Check if this variable is used later
                            if (OptimizedVarUseAnalyzer.usedLater(usage, i + 1, name)) {
                                #if debug_underscore_repair
                                // DISABLED: trace('[UnderscoreRepair] Variable $name IS used later - marking for repair');
                                #end
                                usedUnderscoreVars.set(name, i);
                            } else {
                                #if debug_underscore_repair
                                // DISABLED: trace('[UnderscoreRepair] Variable $name is NOT used later');
                                #end
                            }
                        default:
                            // Not a PVar or not underscore-prefixed - skip
                    }

                // Also handle EBinary(Match, EVar("_name"), rhs) form
                case EBinary(Match, lhs, rhsExpr):
                    switch (lhs.def) {
                        case EVar(name) if (isUnderscorePrefixedUsableVar(name)):
                            #if debug_underscore_repair
                            // DISABLED: trace('[UnderscoreRepair] Found underscore var assignment (EBinary Match): $name at index $i');
                            #end
                            // Check if this variable is used later
                            if (OptimizedVarUseAnalyzer.usedLater(usage, i + 1, name)) {
                                #if debug_underscore_repair
                                // DISABLED: trace('[UnderscoreRepair] Variable $name IS used later - marking for repair');
                                #end
                                usedUnderscoreVars.set(name, i);
                            } else {
                                #if debug_underscore_repair
                                // DISABLED: trace('[UnderscoreRepair] Variable $name is NOT used later');
                                #end
                            }
                        default:
                            // Not an EVar or not underscore-prefixed - skip
                    }

                default:
                    // Not an assignment - skip
            }
        }

        // If no repairs needed, return original
        var hasVarsToRepair = false;
        for (_ in usedUnderscoreVars.keys()) {
            hasVarsToRepair = true;
            break;
        }
        if (!hasVarsToRepair) return stmts;

        // Build rename map: _varname -> varname
        var renames = new Map<String, String>();
        for (name in usedUnderscoreVars.keys()) {
            var baseName = name.substr(1); // Remove leading underscore
            renames.set(name, baseName);
        }

        // Apply renames to all statements
        return [for (stmt in stmts) renameVarsInAST(stmt, renames)];
    }

    /**
     * Check if a variable name is an underscore-prefixed usable variable
     *
     * Returns true for: _this, _result, _value, etc.
     * Returns false for: _, _1, _2, _ignored patterns
     */
    static function isUnderscorePrefixedUsableVar(name: String): Bool {
        if (name == null || name.length < 2) return false;
        if (name.charAt(0) != "_") return false;

        // Skip bare wildcard and numeric patterns
        if (name == "_") return false;

        var secondChar = name.charAt(1);
        // Skip _0, _1, _2 patterns (positional wildcards)
        if (secondChar >= "0" && secondChar <= "9") return false;

        // Skip double-underscore patterns (__something)
        if (secondChar == "_") return false;

        return true;
    }

    /**
     * Rename variables in an AST node according to the rename map
     */
    static function renameVarsInAST(ast: ElixirAST, renames: Map<String, String>): ElixirAST {
        if (ast == null) return ast;

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (renames.exists(name)):
                    makeASTWithMeta(EVar(renames.get(name)), n.metadata, n.pos);

                case EMatch(PVar(name), expr) if (renames.exists(name)):
                    // Rename in pattern variable
                    var renamedExpr = renameVarsInAST(expr, renames);
                    makeASTWithMeta(EMatch(PVar(renames.get(name)), renamedExpr), n.metadata, n.pos);

                // Also handle EBinary(Match, EVar("_name"), rhs) form
                case EBinary(Match, lhs, rhs):
                    switch (lhs.def) {
                        case EVar(name) if (renames.exists(name)):
                            // Rename the variable on the left side of the match
                            var renamedRhs = renameVarsInAST(rhs, renames);
                            makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(renames.get(name)), lhs.metadata, lhs.pos), renamedRhs), n.metadata, n.pos);
                        default:
                            n;
                    }

                case EString(s) if (s != null):
                    // Handle string interpolation: #{_varname} -> #{varname}
                    var renamed = renameInStringInterpolation(s, renames);
                    if (renamed != s) {
                        makeASTWithMeta(EString(renamed), n.metadata, n.pos);
                    } else {
                        n;
                    }

                case ERaw(code) if (code != null):
                    // Handle raw code: replace _varname with varname
                    var renamed = renameInRawCode(code, renames);
                    if (renamed != code) {
                        makeASTWithMeta(ERaw(renamed), n.metadata, n.pos);
                    } else {
                        n;
                    }

                default:
                    n;
            }
        });
    }

    /**
     * Rename variables in string interpolation
     *
     * E.g., "Hello #{_name}" -> "Hello #{name}"
     */
    static function renameInStringInterpolation(s: String, renames: Map<String, String>): String {
        var result = s;
        for (oldName in renames.keys()) {
            var newName = renames.get(oldName);
            // Replace #{_varname} with #{varname}
            result = StringTools.replace(result, '#{$oldName}', '#{$newName}');
            result = StringTools.replace(result, '#{ $oldName }', '#{ $newName }');
            result = StringTools.replace(result, '#{ $oldName}', '#{ $newName}');
            result = StringTools.replace(result, '#{$oldName }', '#{$newName }');
        }
        return result;
    }

    /**
     * Rename variables in raw code
     *
     * Uses token-boundary detection to avoid substring matches
     */
    static function renameInRawCode(code: String, renames: Map<String, String>): String {
        var result = code;

        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }

        for (oldName in renames.keys()) {
            var newName = renames.get(oldName);
            var i = 0;
            var newResult = new StringBuf();
            var lastEnd = 0;

            while (i < result.length) {
                var idx = result.indexOf(oldName, i);
                if (idx == -1) break;

                var before = idx > 0 ? result.charAt(idx - 1) : "";
                var afterIdx = idx + oldName.length;
                var after = afterIdx < result.length ? result.charAt(afterIdx) : "";

                if (!isIdentChar(before) && !isIdentChar(after)) {
                    // This is a valid token boundary - replace
                    newResult.add(result.substring(lastEnd, idx));
                    newResult.add(newName);
                    lastEnd = afterIdx;
                    i = afterIdx;
                } else {
                    i = idx + 1;
                }
            }

            if (lastEnd > 0) {
                newResult.add(result.substring(lastEnd));
                result = newResult.toString();
            }
        }

        return result;
    }
}

#end
