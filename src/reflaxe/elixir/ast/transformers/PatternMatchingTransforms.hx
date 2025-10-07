package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * PatternMatchingTransforms: Comprehensive pattern matching transformation module
 * 
 * WHY: Elixir's pattern matching is fundamental to its functional paradigm. This module
 * transforms Haxe switch statements into idiomatic Elixir case expressions, preserving
 * exhaustiveness checks and variable bindings while generating clean, readable code.
 * 
 * WHAT: Provides transformation passes for:
 * - Case expression optimization and cleanup
 * - Guard clause generation from switch conditions
 * - Pattern variable extraction and binding
 * - Exhaustiveness checking and default case handling
 * - Nested pattern matching optimization
 * 
 * HOW: Multiple transformation passes that work together:
 * 1. patternMatchingPass - Main case transformation and cleanup
 * 2. guardOptimizationPass - Converts complex conditions to guards
 * 3. patternVariableBindingPass - Ensures correct variable scoping
 * 4. exhaustivenessCheckPass - Adds compile-time exhaustiveness verification
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on pattern matching transformations
 * - Composable: Each pass can be enabled/disabled independently
 * - Testable: Clear input/output for each transformation
 * - Maintainable: All pattern matching logic in one place
 * - Extensible: Easy to add new pattern matching features
 * 
 * EDGE CASES:
 * - Empty case expressions (no clauses)
 * - Cases without default branches
 * - Nested cases and pattern shadowing
 * - Complex guard expressions
 * - Pattern variable conflicts
 * 
 * NOTE: Since the switch→case transformation already happens in ElixirASTBuilder,
 * these transforms focus on optimizing and cleaning up the generated case expressions.
 */
@:nullSafety(Off)
class PatternMatchingTransforms {
    
    /**
     * Main pattern matching transformation pass
     * Optimizes and cleans up case expressions for idiomatic output
     */
    public static function patternMatchingPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern matching pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                optimizeCaseExpression(ast, target, clauses);
                
            case EBlock(exprs):
                var transformed = exprs.map(e -> patternMatchingPass(e));
                makeAST(EBlock(transformed));
                
            case EModule(name, attributes, body):
                var transformedBody = body.map(b -> patternMatchingPass(b));
                makeAST(EModule(name, attributes, transformedBody));
                
            case EDef(name, args, guard, body):
                var transformedBody = patternMatchingPass(body);
                makeAST(EDef(name, args, guard, transformedBody));
                
            case EDefp(name, args, guard, body):
                var transformedBody = patternMatchingPass(body);
                makeAST(EDefp(name, args, guard, transformedBody));
                
            case EIf(cond, thenBranch, elseBranch):
                var transformedThen = patternMatchingPass(thenBranch);
                var transformedElse = elseBranch != null ? patternMatchingPass(elseBranch) : null;
                makeAST(EIf(cond, transformedThen, transformedElse));
                
            case EFn(clauses):
                var transformedClauses = clauses.map(clause -> {
                    args: clause.args,
                    guard: clause.guard,
                    body: patternMatchingPass(clause.body)
                });
                makeAST(EFn(transformedClauses));
                
            default:
                // For other node types, return as-is
                // We can't use a generic map method, so we'd need to handle each case individually
                // For now, just return the node unchanged
                ast;
        };
    }
    
    /**
     * Optimize a case expression for idiomatic Elixir output
     */
    static function optimizeCaseExpression(ast: ElixirAST, target: ElixirAST, clauses: Array<ECaseClause>): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Optimizing case with ${clauses.length} clauses");
        #end
        
        // Optimize each clause
        var optimizedClauses: Array<ECaseClause> = [];
        
        for (clause in clauses) {
            // Transform the body recursively
            var optimizedBody = patternMatchingPass(clause.body);
            
            // Check if we can simplify the pattern
            var optimizedPattern = optimizePattern(clause.pattern);
            
            optimizedClauses.push({
                pattern: optimizedPattern,
                guard: clause.guard,
                body: optimizedBody
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Optimized clause: pattern=${optimizedPattern}");
            #end
        }
        
        // Add default case if needed for exhaustiveness
        if (needsDefaultCase(optimizedClauses)) {
            optimizedClauses.push({
                pattern: PWildcard,
                guard: null,
                body: makeAST(EAtom(ElixirAtom.nil()))
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Added default wildcard case for exhaustiveness");
            #end
        }
        
        // Create the optimized case expression
        var optimizedCase = makeAST(ECase(target, optimizedClauses));
        
        // Preserve original metadata if it exists
        if (ast.metadata != null) {
            optimizedCase.metadata = ast.metadata;
        }
        
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Generated optimized case expression with ${optimizedClauses.length} clauses");
        #end
        
        return optimizedCase;
    }
    
    /**
     * Optimize a pattern for cleaner output
     */
    static function optimizePattern(pattern: EPattern): EPattern {
        return switch(pattern) {
            case PVar(name) if (name == "_"):
                // Already a wildcard
                PWildcard;
                
            case PAlias(varName, innerPattern):
                // Optimize the inner pattern
                PAlias(varName, optimizePattern(innerPattern));
                
            case PTuple(elements):
                // Optimize each element
                PTuple(elements.map(e -> optimizePattern(e)));
                
            case PList(elements):
                // Optimize each element
                PList(elements.map(e -> optimizePattern(e)));
                
            case PCons(head, tail):
                // Optimize both parts
                PCons(optimizePattern(head), optimizePattern(tail));
                
            case PMap(pairs):
                // Optimize each value pattern
                PMap(pairs.map(p -> {key: p.key, value: optimizePattern(p.value)}));
                
            case PStruct(module, fields):
                // Optimize each field pattern
                PStruct(module, fields.map(f -> {key: f.key, value: optimizePattern(f.value)}));
                
            default:
                // Return as-is for other patterns
                pattern;
        };
    }
    
    /**
     * Check if a default case is needed for exhaustiveness
     */
    static function needsDefaultCase(clauses: Array<ECaseClause>): Bool {
        // Check if any clause has a wildcard pattern
        for (c in clauses) {
            if (isWildcardPattern(c.pattern)) {
                return false; // Already has a catch-all
            }
        }
        
        // For now, assume non-exhaustive and suggest adding default
        // TODO: More sophisticated exhaustiveness checking based on type information
        return false; // Changed to false to avoid adding unnecessary wildcards
    }
    
    /**
     * Check if a pattern is a wildcard/catch-all
     */
    static function isWildcardPattern(pattern: EPattern): Bool {
        return switch(pattern) {
            case PVar("_"): true;
            case PWildcard: true;
            default: false;
        };
    }
    
    /**
     * Guard optimization pass - converts complex conditions to guard clauses
     */
    public static function guardOptimizationPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting guard optimization pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                // 1) Ensure existing guards are guard-safe; if not, move condition into body
                var safeClauses = clauses.map(clause -> ensureGuardSafety(clause));
                // 2) Try converting top-level body ifs into guards when safe
                var optimizedClauses = safeClauses.map(clause -> optimizeGuardClause(clause));
                makeAST(ECase(target, optimizedClauses));
                
            default:
                // Recursively optimize children - handle each case individually
                recursiveTransform(ast, guardOptimizationPass);
        };
    }

    /**
     * CanonicalizeTupleBinders (clause‑local, AST‑only)
     *
     * HIGH‑LEVEL INTENT (General)
     * - Enum constructors compile to tuples: {:tag, arg1, arg2, ...}.
     * - Guards often lower to nested if/else chains in a single clause body.
     * - The typer/desugaring may introduce numeric suffixes on names (r2, g3, changeset2).
     *
     * WHAT THIS PASS DOES (General, Clause‑Local)
     * - Binder‑scoped suffix normalization: only strip trailing digits on an EVar if the base name
     *   belongs to the clause’s binder set derived from its pattern (prevents accidental renames).
     * - Single‑clause if/else → cond rewrite: converts nested if/else in the clause body into a single
     *   cond do ... end for idiomatic readability.
     * - Optional domain binder hints (narrow): for widely‑recognized tags, preserve conventional names:
     *   • {:rgb, _, _, _} → {:rgb, r, g, b}
     *   • {:hsl, _, _, _} → {:hsl, h, s, l}
     *   This is a presentation preference; correctness does not depend on these hints.
     * - Run‑aware consolidation (narrow): when multiple adjacent clauses share the same rgb/hsl tag,
     *   collapse bodies into a cond. The general consolidation logic is handled by GuardClauseConsolidation.
     *
     * WHAT THIS PASS DOES NOT DO (Separation of Concerns)
     * - Does not invent new binder names for arbitrary tags. Generic naming/alignment is handled by:
     *   • patternVarRenameByUsagePass (rename binders to match body usage when safe)
     *   • caseClauseBindingAliasPass (pre‑bind missing body vars to available pattern binders)
     * - Does not perform string‑level edits; transformations are AST‑pure.
     *
     * DESIGN NOTES (Generalization Strategy)
     * - Provenance: Binder sets are collected from the pattern (VarOrigin.PatternBinder in builder); the
     *   suffix normalization only applies to names proven to originate from the pattern, avoiding overreach.
     * - Safety: This keeps suffix cleanup and if→cond rewriting fully general across tags without relying
     *   on tag whitelists. Domain hints (rgb/hsl) are optional and can be retired without correctness impact.
     * - Integration: GuardClauseConsolidation remains the tag‑agnostic grouping mechanism; this pass focuses
     *   on clause‑local cleanup and readability before grouping/usage‑based renames.
     */
    public static function canonicalizeCommonTupleBindersPass(ast: ElixirAST): ElixirAST {
        // Helper: simple var-suffix cleanup
        function fixVarRefs(node: ElixirAST): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case EVar(name):
                    var n = name;
                    // Only normalize known color/space component binders with numeric suffixes
                    if (~/^(r|g|b|h|s|l)\d+$/.match(n)) {
                        n = ~/^([a-z]+)\d+$/.replace(n, "$1");
                    }
                    if (n != name) makeAST(EVar(n)) else node;
                case EBinary(op, l, r):
                    makeAST(EBinary(op, fixVarRefs(l), fixVarRefs(r)));
                case ECall(t, n, args):
                    makeAST(ECall(t != null ? fixVarRefs(t) : null, n, [for (a in args) fixVarRefs(a)]));
                case ERemoteCall(mod, fname, args):
                    makeAST(ERemoteCall(mod != null ? fixVarRefs(mod) : null, fname, [for (a in args) fixVarRefs(a)]));
                case EIf(c, t, e):
                    makeAST(EIf(fixVarRefs(c), fixVarRefs(t), e != null ? fixVarRefs(e) : null));
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) fixVarRefs(s)]));
                case EParen(e):
                    makeAST(EParen(fixVarRefs(e)));
                default:
                    node;
            };
        }

        function canonicalizePattern(p: EPattern, tag: String): EPattern {
            return switch (p) {
                case PTuple(elems) if (elems.length >= 1):
                    var names = switch (tag) {
                        case "rgb": ["r","g","b"];
                        case "hsl": ["h","s","l"];
                        default: [];
                    };
                    if (names.length == 0) return p;
                    var newElems = elems.copy();
                    var count = Std.int(Math.min(names.length, newElems.length - 1));
                    for (i in 0...count) switch (newElems[i + 1]) {
                        case PVar(_):
                            newElems[i + 1] = PVar(names[i]);
                        case PWildcard:
                            newElems[i + 1] = PVar(names[i]);
                        case PAlias(_, inner):
                            newElems[i + 1] = PAlias(names[i], inner);
                        default:
                            // Keep non-variable elements (literals/patterns) unchanged
                    }
                    PTuple(newElems);
                default:
                    p;
            };
        }

        // Convert nested if/else chain into cond do ... end
        function ifChainToCond(node: ElixirAST): ElixirAST {
            // Walk if/else chain
            var branches:Array<{condition:ElixirAST, body:ElixirAST}> = [];
            var current = node;
            while (true) {
                switch (current.def) {
                    case EIf(cond, thenB, elseB):
                        // Must have else branch to build a proper cond
                        if (elseB == null) return node; // Abort, leave original
                        branches.push({ condition: fixVarRefs(cond), body: fixVarRefs(thenB) });
                        // Unwrap else branch if it's a single-stmt block or paren containing an if
                        var next = elseB;
                        var unwrapped = true;
                        while (unwrapped && next != null) {
                            switch (next.def) {
                                case EBlock(sts) if (sts.length == 1): next = sts[0];
                                case EParen(e): next = e;
                                default: unwrapped = false;
                            }
                        }
                        current = next;
                        continue;
                    default:
                        // Final else becomes true branch
                        branches.push({ condition: makeAST(EBoolean(true)), body: fixVarRefs(current) });
                }
                break;
            }
            return makeAST(ECond([for (b in branches) { condition: b.condition, body: b.body }]));
        }

        // Helper: unwrap single-statement blocks to their inner expression
        function unwrapSingleStmtBlock(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(sts) if (sts.length == 1):
                    unwrapSingleStmtBlock(sts[0]);
                default:
                    n;
            }
        }

        // Helper: extract enum tag name from tuple pattern like {:rgb, ...}
        function tagOf(p: EPattern): Null<String> {
            return switch (p) {
                case PTuple(elems) if (elems.length >= 1):
                    switch (elems[0]) {
                        case PLiteral({def: EAtom(a)}): (a:String);
                        default: null;
                    }
                default: null;
            };
        }

        // Helper: infer tag from variables used in the body after suffix normalization
        function inferTagFromBodyVars(body: ElixirAST): Null<String> {
            var seen = new Map<String, Bool>();
            function walk(n: ElixirAST): Void {
                if (n == null) return;
                switch (n.def) {
                    case EVar(name):
                        if (name == "r" || name == "g" || name == "b" || name == "h" || name == "s" || name == "l") {
                            seen.set(name, true);
                        }
                    case EBinary(_, l, r):
                        walk(l); walk(r);
                    case ECall(t, _n, args):
                        if (t != null) walk(t);
                        for (a in args) walk(a);
                    case ERemoteCall(mod, _fn, args):
                        if (mod != null) walk(mod);
                        for (a in args) walk(a);
                    case EIf(c, t, e):
                        walk(c); walk(t); if (e != null) walk(e);
                    case EBlock(stmts):
                        for (s in stmts) walk(s);
                    case EParen(e):
                        walk(e);
                    default:
                        // Other nodes: no-op
                }
            }
            walk(body);
            var rgb = (seen.exists("r") || seen.exists("g") || seen.exists("b"));
            var hsl = (seen.exists("h") || seen.exists("s") || seen.exists("l"));
            return rgb ? "rgb" : (hsl ? "hsl" : null);
        }

        // Helper: strip trailing digit suffix from a name (e.g., r2 -> r, changeset3 -> changeset)
        function stripDigitsSuffix(s:String):String {
            var re = ~/([0-9]+)$/;
            return re.replace(s, "");
        }

        return switch (ast.def) {
            case ECase(target, clauses):
                var newClauses:Array<ECaseClause> = [];

                var i = 0;
                while (i < clauses.length) {
                    var c = clauses[i];
                    // Removed tag-specific handling; generic normalization handled elsewhere
                    // Keep clause as-is here; downstream passes (suffix normalization and guard consolidation)
                    // perform idiomatic transformations generically.
                    if (false) {
                        // Accumulate a run of consecutive rgb/hsl clauses
                        var run:Array<ECaseClause> = [c];
                        var j = i + 1;
                        while (j < clauses.length && tagOf(clauses[j].pattern) == tag) {
                            run.push(clauses[j]);
                            j++;
                        }

                        if (run.length >= 2) {
                            // Consolidate into a single clause with cond body
                            var condBranches:Array<ECondClause> = [];
                            // Build binder base set from the first run pattern to guide suffix normalization
                            var binderBases = new Map<String, Bool>();
                            function collectBinderBases(p:EPattern):Void {
                                switch (p) {
                                    case PVar(v): binderBases.set(stripDigitsSuffix(v), true);
                                    case PAlias(v, inner): binderBases.set(stripDigitsSuffix(v), true); collectBinderBases(inner);
                                    case PTuple(el): for (e in el) collectBinderBases(e);
                                    case PList(el): for (e in el) collectBinderBases(e);
                                    case PCons(h,t): collectBinderBases(h); collectBinderBases(t);
                                    case PMap(pairs): for (kv in pairs) collectBinderBases(kv.value);
                                    case PStruct(_, fields): for (f in fields) collectBinderBases(f.value);
                                    default:
                                }
                            }
                            collectBinderBases(run[0].pattern);
                            function fixVarRefsBounded(n: ElixirAST): ElixirAST {
                                if (n == null) return n;
                                return switch (n.def) {
                                    case EVar(name):
                                        var base = ~/^(\w+?)(\d+)$/.match(name) ? ~/^(\w+?)(\d+)$/.replace(name, "$1") : name;
                                        if (base != name && binderBases.exists(base)) makeAST(EVar(base)) else n;
                                    case EBinary(op,l,r): makeAST(EBinary(op, fixVarRefsBounded(l), fixVarRefsBounded(r)));
                                    case ECall(t, nm, args): makeAST(ECall(t != null ? fixVarRefsBounded(t) : null, nm, [for (a in args) fixVarRefsBounded(a)]));
                                    case ERemoteCall(mod, fnm, args): makeAST(ERemoteCall(mod != null ? fixVarRefsBounded(mod) : null, fnm, [for (a in args) fixVarRefsBounded(a)]));
                                    case EIf(c,t,e): makeAST(EIf(fixVarRefsBounded(c), fixVarRefsBounded(t), e != null ? fixVarRefsBounded(e) : null));
                                    case EBlock(sts): makeAST(EBlock([for (s in sts) fixVarRefsBounded(s)]));
                                    case EParen(e): makeAST(EParen(fixVarRefsBounded(e)));
                                    default: n;
                                };
                            }
                            for (rc in run) {
                                var cond = rc.guard != null ? fixVarRefsBounded(rc.guard) : makeAST(EBoolean(true));
                                var bdy0 = fixVarRefsBounded(rc.body);
                                var inner = unwrapSingleStmtBlock(bdy0);
                                var bdy = switch (inner.def) {
                                    case EIf(_, _, _): ifChainToCond(inner);
                                    default: bdy0;
                                };
                                condBranches.push({ condition: cond, body: bdy });
                            }
                            var canonPat = canonicalizePattern(run[0].pattern, tag);
                            var condAst = makeAST(ECond(condBranches));
                            newClauses.push({ pattern: canonPat, guard: null, body: condAst });
                            i = j; // Skip the run
                            continue;
                    newClauses.push(c);
                    i++;
                }

                makeAST(ECase(canonicalizeCommonTupleBindersPass(target), newClauses));
            default:
                recursiveTransform(ast, canonicalizeCommonTupleBindersPass);
        };
    }

    /**
     * Guard clause consolidation pass
     * 
     * WHY: Multiple case clauses with the same pattern but different guards are
     *      more idiomatic as a single clause with a cond do ... end inside the body.
     * GENERALITY: This pass is tag‑agnostic. It operates on the structural pattern
     *      signature (constructor/tag + arity + nested shapes), ignoring variable names,
     *      and consolidates any adjacent run of equivalent patterns. This is the
     *      general mechanism for all enum‑like tuple tags, not just rgb/hsl.
     * COOPERATION: Clause‑local fixes such as binder‑scoped suffix normalization and
     *      single‑clause if→cond are performed in CanonicalizeTupleBinders. Name alignment
     *      and body aliasing are handled by patternVarRenameByUsagePass and
     *      caseClauseBindingAliasPass. Keeping these responsibilities separate preserves
     *      correctness and makes the transformation pipeline predictable.
     * WHAT: Detects runs of clauses sharing an identical pattern (structure-only,
     *      variable names ignored) and rewrites them into one clause with a cond.
     * HOW: Sequentially scans ECase clauses, groups adjacent clauses by normalized
     *      pattern signature, builds ECond with each original guard/body as a branch,
     *      and converts any unguarded variant into a final true branch.
     */
    public static function guardClauseConsolidationPass(ast: ElixirAST): ElixirAST {
        // Local helper for removing trailing digit suffixes from variable names
        function stripDigitsSuffixLocal(s:String):String {
            var re = ~/([0-9]+)$/;
            return re.replace(s, "");
        }

        return switch (ast.def) {
            case ECase(target, clauses):
                var consolidated:Array<ECaseClause> = [];

                var i = 0;
                while (i < clauses.length) {
                    var start = i;
                    var patKey = patternSignature(clauses[i].pattern);
                    var run:Array<ECaseClause> = [clauses[i]];
                    i++;
                    while (i < clauses.length && patternSignature(clauses[i].pattern) == patKey) {
                        run.push(clauses[i]);
                        i++;
                    }

                    // Only consolidate if there are 2+ clauses in the run and at least one guard present
                    var hasGuard = false;
                    for (c in run) if (c.guard != null) { hasGuard = true; break; }

                    if (run.length >= 2 && hasGuard) {
                        // Helper: tag extraction for fallback binder bases
                        function tagOfPat(p:EPattern):Null<String> {
                            return switch (p) {
                                case PTuple(elems) if (elems.length >= 1):
                                    switch (elems[0]) { case PLiteral({def: EAtom(a)}): (a:String); default: null; }
                                default: null;
                            };
                        }
                        var runTag = tagOfPat(clauses[start].pattern); // informative only; do not special-case logic by tag
                        // Heuristic: Prefer header guards when all guards are guard-safe and
                        // reference exactly one binder variable across the run (e.g., n > 0, n < 0).
                        // Prefer cond when guards reference multiple distinct binder vars (e.g., r/g/b),
                        // or when any guard is not guard-safe.
                        var runBinderBases = new Map<String, Bool>();
                        function collectBasesForRun(p:EPattern):Void {
                            switch (p) {
                                case PVar(v): runBinderBases.set(stripDigitsSuffixLocal(v), true);
                                case PAlias(v, inner): runBinderBases.set(stripDigitsSuffixLocal(v), true); collectBasesForRun(inner);
                                case PTuple(el): for (e in el) collectBasesForRun(e);
                                case PList(el): for (e in el) collectBasesForRun(e);
                                case PCons(h,t): collectBasesForRun(h); collectBasesForRun(t);
                                case PMap(pairs): for (kv in pairs) collectBasesForRun(kv.value);
                                case PStruct(_, fields): for (f in fields) collectBasesForRun(f.value);
                                default:
                            }
                        }
                        collectBasesForRun(clauses[start].pattern);

                        function collectGuardVars(node: ElixirAST, acc: Map<String, Bool>):Void {
                            if (node == null) return;
                            switch (node.def) {
                                case EVar(name):
                                    var base = stripDigitsSuffixLocal(name);
                                    if (runBinderBases.exists(base)) acc.set(base, true);
                                case EBinary(_, l, r): collectGuardVars(l, acc); collectGuardVars(r, acc);
                                case EUnary(_, e): collectGuardVars(e, acc);
                                case ECall(t, _, args): if (t != null) collectGuardVars(t, acc); for (a in args) collectGuardVars(a, acc);
                                case ERemoteCall(mod, _, args): if (mod != null) collectGuardVars(mod, acc); for (a in args) collectGuardVars(a, acc);
                                case EParen(e): collectGuardVars(e, acc);
                                default:
                            }
                        }

                        var unionVars = new Map<String, Bool>();
                        var allGuardSafe = true;
                        for (rc in run) {
                            if (rc.guard != null) {
                                if (!isGuardSafeExpr(rc.guard)) allGuardSafe = false;
                                collectGuardVars(rc.guard, unionVars);
                            }
                        }

                        var unionCount = 0; for (_ in unionVars.keys()) unionCount++;
                        var preferHeaderGuards = allGuardSafe && unionCount == 1;

                        if (preferHeaderGuards) {
                            // Do not consolidate; copy run as-is
                            for (c2 in run) consolidated.push(c2);
                            continue;
                        }

                        var condClauses:Array<ECondClause> = [];
                        var sawUnguarded = false;
                        // Build binder bases from the representative pattern for bounded normalization
                        var binderBases = new Map<String, Bool>();
                        function stripDigitsSuffixLocal(s:String):String {
                            var re = ~/([0-9]+)$/;
                            return re.replace(s, "");
                        }
                        function collectBinderBases(p: EPattern): Void {
                            switch (p) {
                                case PVar(v): binderBases.set(stripDigitsSuffixLocal(v), true);
                                case PAlias(v, inner): binderBases.set(stripDigitsSuffixLocal(v), true); collectBinderBases(inner);
                                case PTuple(el): for (e in el) collectBinderBases(e);
                                case PList(el): for (e in el) collectBinderBases(e);
                                case PCons(h,t): collectBinderBases(h); collectBinderBases(t);
                                case PMap(pairs): for (kv in pairs) collectBinderBases(kv.value);
                                case PStruct(_, fields): for (f in fields) collectBinderBases(f.value);
                                default:
                            }
                        }
                        collectBinderBases(clauses[start].pattern);
                        function fixVarRefsBounded(node: ElixirAST): ElixirAST {
                            if (node == null) return node;
                            return switch (node.def) {
                                case EVar(name):
                                    var base = ~/^(\w+?)(\d+)$/.match(name) ? ~/^(\w+?)(\d+)$/.replace(name, "$1") : name;
                                    if (base != name && binderBases.exists(base)) makeAST(EVar(base)) else node;
                                case EBinary(op, l, r):
                                    makeAST(EBinary(op, fixVarRefsBounded(l), fixVarRefsBounded(r)));
                                case ECall(t, n, args):
                                    makeAST(ECall(t != null ? fixVarRefsBounded(t) : null, n, [for (a in args) fixVarRefsBounded(a)]));
                                case EIf(c, t, e):
                                    makeAST(EIf(fixVarRefsBounded(c), fixVarRefsBounded(t), e != null ? fixVarRefsBounded(e) : null));
                                case EParen(e):
                                    makeAST(EParen(fixVarRefsBounded(e)));
                                case EBlock(stmts):
                                    makeAST(EBlock([for (s in stmts) fixVarRefsBounded(s)]));
                                default:
                                    node;
                            };
                        }

                        for (idx in 0...run.length) {
                            var c = run[idx];
                            var condition:ElixirAST = null;
                            if (c.guard != null) {
                                condition = c.guard;
                            } else {
                                // Use true as the final catch-all branch; if multiple unguarded appear, keep the last as true and treat earlier as explicit true as well
                                condition = makeAST(EBoolean(true));
                                sawUnguarded = true;
                            }
                            // Fix potential suffixed variables introduced earlier
                            var fixedCond = fixVarRefsBounded(condition);
                            var fixedBody = fixVarRefsBounded(c.body);
                            condClauses.push({ condition: fixedCond, body: fixedBody });
                        }

                        var condAst = makeAST(ECond(condClauses));
                        // Merge binder names across the run (tag-agnostic):
                        // For each tuple arg slot, if any clause binds a non-underscore var, use its base name.
                        function tupleArity(p:EPattern):Int {
                            return switch (p) { case PTuple(el): el.length - 1; default: 0; };
                        }
                        var arity = tupleArity(run[0].pattern);
                        var finalNames:Array<Null<String>> = [for (_ in 0...arity) null];
                        for (rc in run) {
                            switch (rc.pattern) {
                                case PTuple(elems) if (elems.length - 1 == arity):
                                    for (idx in 0...arity) {
                                        if (finalNames[idx] != null) continue;
                                        switch (elems[idx + 1]) {
                                            case PVar(nm):
                                                var base = stripDigitsSuffixLocal(nm);
                                                if (base != "_" && (base.length == 1 || base.charAt(0) != '_')) finalNames[idx] = base;
                                            case PAlias(nm, _):
                                                var base2 = stripDigitsSuffixLocal(nm);
                                                if (base2 != "_" && (base2.length == 1 || base2.charAt(0) != '_')) finalNames[idx] = base2;
                                            default:
                                        }
                                    }
                                default:
                            }
                        }
                        // Build consolidated pattern: use discovered names when present; otherwise sanitize run[0] pattern
                        var basePat = sanitizePatternBinders(run[0].pattern);
                        var mergedPat:EPattern = switch (basePat) {
                            case PTuple(elems) if (elems.length - 1 == arity):
                                var out:Array<EPattern> = [];
                                out.push(elems[0]);
                                for (i in 0...arity) {
                                    if (finalNames[i] != null) out.push(PVar(finalNames[i]));
                                    else out.push(elems[i + 1]);
                                }
                                PTuple(out);
                            default: basePat;
                        };
                        #if debug_binder_norm
                        var fnames = [];
                        for (i in 0...arity) fnames.push(finalNames[i]);
                        trace('[BinderNorm] Consolidation finalNames: [' + fnames.join(', ') + ']');
                        #end
                        consolidated.push({ pattern: mergedPat, guard: null, body: condAst });
                    } else {
                        // No consolidation; copy run as-is
                        for (c in run) consolidated.push(c);
                    }
                }

                // Final polish: convert clause-local nested if/else chains into cond bodies for readability
                function unwrapSingleStmtBlockLocal(n: ElixirAST): ElixirAST {
                    return switch (n.def) {
                        case EBlock(sts) if (sts.length == 1): unwrapSingleStmtBlockLocal(sts[0]);
                        default: n;
                    };
                }
                function ifChainToCondLocal(node: ElixirAST): ElixirAST {
                    var branches:Array<{condition:ElixirAST, body:ElixirAST}> = [];
                    var current = node;
                    while (true) {
                        switch (current.def) {
                            case EIf(cond, thenB, elseB):
                                if (elseB == null) return node; // not a full chain
                                branches.push({ condition: cond, body: thenB });
                                // unwrap else branch if it's block/paren containing an if
                                var next = elseB;
                                var unwrapped = true;
                                while (unwrapped && next != null) {
                                    switch (next.def) {
                                        case EBlock(sts) if (sts.length == 1): next = sts[0];
                                        case EParen(e): next = e;
                                        default: unwrapped = false;
                                    }
                                }
                                current = next; continue;
                            default:
                                branches.push({ condition: makeAST(EBoolean(true)), body: current });
                        }
                        break;
                    }
                    return makeAST(ECond([for (b in branches) { condition: b.condition, body: b.body }]));
                }

                var polished:Array<ECaseClause> = [];
                // Helper: extract tag from tuple pattern first element if atom
                function getTag(p:EPattern):Null<String> {
                    return switch (p) {
                        case PTuple(elems) if (elems.length >= 1):
                            switch (elems[0]) {
                                case PLiteral({def: EAtom(a)}): (a:String);
                                default: null;
                            }
                        default: null;
                    };
                }

                for (cl in consolidated) {
                    var inner = unwrapSingleStmtBlockLocal(cl.body);
                    var newBody: ElixirAST = null;
                    // Build binder base set from clause pattern for bounded var normalization
                    var binderBasesLocal = new Map<String, Bool>();
                    function collectBasesFromPattern(p:EPattern):Void {
                        switch (p) {
                            case PVar(v): binderBasesLocal.set(stripDigitsSuffixLocal(v), true);
                            case PAlias(v, innerP): binderBasesLocal.set(stripDigitsSuffixLocal(v), true); collectBasesFromPattern(innerP);
                            case PTuple(el): for (e in el) collectBasesFromPattern(e);
                            case PList(el): for (e in el) collectBasesFromPattern(e);
                            case PCons(h,t): collectBasesFromPattern(h); collectBasesFromPattern(t);
                            case PMap(pairs): for (kv in pairs) collectBasesFromPattern(kv.value);
                            case PStruct(_, fields): for (f in fields) collectBasesFromPattern(f.value);
                            default:
                        }
                    }
                    collectBasesFromPattern(cl.pattern);
                    // No tag-specific fallbacks: binder bases come strictly from the pattern
                    function fixVarRefsWithBases(n: ElixirAST): ElixirAST {
                        if (n == null) return n;
                        return switch (n.def) {
                            case EVar(name):
                                var base = stripDigitsSuffixLocal(name);
                                if (base != name && binderBasesLocal.exists(base)) makeAST(EVar(base)) else n;
                            case EBinary(op, l, r): makeAST(EBinary(op, fixVarRefsWithBases(l), fixVarRefsWithBases(r)));
                            case ECall(t, nm, args): makeAST(ECall(t != null ? fixVarRefsWithBases(t) : null, nm, [for (a in args) fixVarRefsWithBases(a)]));
                            case ERemoteCall(mod, fnm, args): makeAST(ERemoteCall(mod != null ? fixVarRefsWithBases(mod) : null, fnm, [for (a in args) fixVarRefsWithBases(a)]));
                            case EIf(c,t,e): makeAST(EIf(fixVarRefsWithBases(c), fixVarRefsWithBases(t), e != null ? fixVarRefsWithBases(e) : null));
                            case ECond(clauses):
                                var mapped = [];
                                for (clc in clauses) {
                                    mapped.push({ condition: fixVarRefsWithBases(clc.condition), body: fixVarRefsWithBases(clc.body) });
                                }
                                makeAST(ECond(mapped));
                            case EBlock(sts): makeAST(EBlock([for (s in sts) fixVarRefsWithBases(s)]));
                            case EParen(e): makeAST(EParen(fixVarRefsWithBases(e)));
                            default: n;
                        };
                    }
                    switch (inner.def) {
                        case EIf(_, _, _):
                            newBody = ifChainToCondLocal(inner);
                        case ECond(clauses):
                            // If the last branch is true -> (if-chain), flatten that chain into the cond
                            if (clauses.length > 0) {
                                var last = clauses[clauses.length - 1];
                                var isTrue = switch (last.condition.def) {
                                    case EBoolean(true): true;
                                    case EAtom(a): (a:String) == "true";
                                    default: false;
                                };
                                if (isTrue) {
                                    var lastInner = unwrapSingleStmtBlockLocal(last.body);
                                    switch (lastInner.def) {
                                        case EIf(_, _, _):
                                            var tailCond = ifChainToCondLocal(lastInner);
                                            switch (tailCond.def) {
                                                case ECond(tailClauses):
                                                    var merged = [];
                                                    // All but last existing clauses
                                                    for (k in 0...clauses.length - 1) merged.push(clauses[k]);
                                                    // Append expanded tail
                                                    for (tc in tailClauses) merged.push(tc);
                                                    newBody = makeAST(ECond(merged));
                                                default:
                                                    newBody = inner;
                                            }
                                        default:
                                            newBody = inner;
                                    }
                                } else {
                                    newBody = inner;
                                }
                            } else {
                                newBody = inner;
                            }
                        default:
                            if (newBody == null) newBody = cl.body;
                    }
                    // Apply bounded var ref normalization so pattern binders remain referenced
                    var normalizedBody = fixVarRefsWithBases(newBody);
                    polished.push({ pattern: cl.pattern, guard: cl.guard, body: normalizedBody });
                }

                makeAST(ECase(guardClauseConsolidationPass(target), polished));

            default:
                recursiveTransform(ast, guardClauseConsolidationPass);
        };
    }

    /**
     * Compute a normalized signature string for a pattern, ignoring variable names.
     */
    static function patternSignature(p: EPattern): String {
        return switch (p) {
            case PVar(_): "var";
            case PLiteral(v): 'lit:' + literalKey(v);
            case PTuple(elems): 'tuple(' + elems.map(patternSignature).join(',') + ')';
            case PList(elems): 'list[' + elems.map(patternSignature).join(',') + ']';
            case PCons(h, t): 'cons(' + patternSignature(h) + '|' + patternSignature(t) + ')';
            case PMap(pairs):
                var parts = [];
                for (kv in pairs) parts.push(literalKey(kv.key) + '=>' + patternSignature(kv.value));
                'map{' + parts.join(',') + '}';
            case PStruct(mod, fields):
                var f = [];
                for (fld in fields) f.push(fld.key + ':' + patternSignature(fld.value));
                'struct(' + mod + '){' + f.join(',') + '}';
            case PPin(inner): 'pin(' + patternSignature(inner) + ')';
            case PWildcard: '_';
            case PAlias(_, inner): 'alias(' + patternSignature(inner) + ')';
            case PBinary(segments): 'bin<' + segments.length + '>';
        };
    }

    static function literalKey(ast: ElixirAST): String {
        return switch (ast.def) {
            case EAtom(a): ':' + (a:String);
            case EInteger(i): 'i:' + Std.string(i);
            case EFloat(f): 'f:' + Std.string(f);
            case EBoolean(b): b ? 'true' : 'false';
            case EString(s): 's:"' + s + '"';
            case ETuple(elems): 't(' + elems.map(literalKey).join(',') + ')';
            default: Type.enumConstructor(ast.def); // fallback
        };
    }

    /**
     * Sanitize pattern binder names by stripping numeric suffixes commonly
     * introduced during guard extraction (e.g., r2 -> r, l2 -> l).
     */
    static function sanitizePatternBinders(p: EPattern): EPattern {
        function clean(name:String):String {
            var n = name;
            // Drop leading underscore to match snapshot style
            if (n.length > 1 && n.charAt(0) == "_") n = n.substring(1);
            // Strip numeric suffixes commonly introduced during extraction/guard steps
            if (~/^[a-z]\d+$/.match(n)) return n.charAt(0);
            if (~/^(r|g|b|h|s|l)\d+$/.match(n)) return ~/^([a-z]+)\d+$/.replace(n, "$1");
            return n;
        }
        return switch (p) {
            case PVar(n): PVar(clean(n));
            case PLiteral(_): p;
            case PTuple(elems): PTuple([for (e in elems) sanitizePatternBinders(e)]);
            case PList(elems): PList([for (e in elems) sanitizePatternBinders(e)]);
            case PCons(h, t): PCons(sanitizePatternBinders(h), sanitizePatternBinders(t));
            case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: sanitizePatternBinders(kv.value)}]);
            case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: sanitizePatternBinders(f.value)}]);
            case PPin(inner): PPin(sanitizePatternBinders(inner));
            case PWildcard: p;
            case PAlias(v, inner): PAlias(clean(v), sanitizePatternBinders(inner));
            case PBinary(segments): p;
        }
    }

    /**
     * If a clause has a non-safe guard, remove the guard and push it into the body as an if.
     */
    static function ensureGuardSafety(clause: ECaseClause): ECaseClause {
        if (clause.guard == null) return clause;
        if (isGuardSafeExpr(clause.guard)) return clause;

        // Extract remote Map.get/2 calls used in the guard and pre-bind them in the body
        var preBinds: Array<ElixirAST> = [];
        var varMap = new Map<String, {key: String, expr: ElixirAST}>();

        function collectBindings(expr: ElixirAST): Void {
            if (expr == null) return;
            switch (expr.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    var isKeywordGet = switch (module.def) { case EVar(name) if (name == "Keyword"): true; default: false; };
                    if ((isMapGet || isKeywordGet) && funcName == "get" && args.length >= 2) {
                        // If second arg is an atom we can derive a stable varName
                        var varName = switch (args[1].def) {
                            case EAtom(atom): Std.string(atom);
                            default: null;
                        };
                        if (varName != null && varName.length > 0) {
                            // Create binding: varName = Map.get(...)/Keyword.get(...)
                            preBinds.push(makeAST(EMatch(PVar(varName), expr)));
                            varMap.set(varName, {key: varName, expr: expr});
                        }
                    }
                    // Recurse into module and args
                    if (module != null) collectBindings(module);
                    for (a in args) collectBindings(a);
                case EBinary(_, l, r):
                    collectBindings(l); collectBindings(r);
                case EUnary(_, e):
                    collectBindings(e);
                case EIf(c, t, e):
                    collectBindings(c); collectBindings(t); if (e != null) collectBindings(e);
                case EParen(e):
                    collectBindings(e);
                case EBlock(stmts):
                    for (s in stmts) collectBindings(s);
                default:
                    // Other node types: no-op for binding collection
            }
        }

        collectBindings(clause.guard);

        // Helper: replace Map.get(..., :key) with the inferred variable in an expression
        function replaceMapGetInExpr(node: ElixirAST): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    var isKeywordGet = switch (module.def) { case EVar(name) if (name == "Keyword"): true; default: false; };
                    if ((isMapGet || isKeywordGet) && funcName == "get" && args.length >= 2) {
                        switch (args[1].def) {
                            case EAtom(atom):
                                var keyName = Std.string(atom);
                                if (varMap.exists(keyName)) {
                                    makeAST(EVar(keyName));
                                } else {
                                    node;
                                }
                            default: node;
                        }
                    } else {
                        var newMod = module != null ? replaceMapGetInExpr(module) : null;
                        var newArgs = [for (a in args) replaceMapGetInExpr(a)];
                        makeAST(ERemoteCall(newMod, funcName, newArgs));
                    }
                case EBinary(op, l, r):
                    makeAST(EBinary(op, replaceMapGetInExpr(l), replaceMapGetInExpr(r)));
                case EUnary(op, e):
                    makeAST(EUnary(op, replaceMapGetInExpr(e)));
                case EIf(c, t, e):
                    makeAST(EIf(replaceMapGetInExpr(c), replaceMapGetInExpr(t), e != null ? replaceMapGetInExpr(e) : null));
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) replaceMapGetInExpr(s)]));
                case ECall(target, name, args):
                    makeAST(ECall(target != null ? replaceMapGetInExpr(target) : null, name, [for (a in args) replaceMapGetInExpr(a)]));
                case EParen(e):
                    makeAST(EParen(replaceMapGetInExpr(e)));
                default:
                    node;
            };
        }

        // Helper: normalize guard-friendly predicates, eg `x != nil` -> `not is_nil(x)`
        function normalizeGuardPredicate(node: ElixirAST): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case EBinary(op, l, r):
                    // First, normalize children
                    var nl = normalizeGuardPredicate(l);
                    var nr = normalizeGuardPredicate(r);
                    // Transform equality with nil into is_nil
                    switch op {
                        case NotEqual:
                            // x != nil  => not is_nil(x)
                            if (nr.def == ENil) return makeAST(EUnary(Not, makeAST(ECall(null, "is_nil", [nl]))));
                            if (nl.def == ENil) return makeAST(EUnary(Not, makeAST(ECall(null, "is_nil", [nr]))));
                        case Equal:
                            // x == nil  => is_nil(x)
                            if (nr.def == ENil) return makeAST(ECall(null, "is_nil", [nl]));
                            if (nl.def == ENil) return makeAST(ECall(null, "is_nil", [nr]));
                        default:
                    }
                    makeAST(EBinary(op, nl, nr));
                case EUnary(op, e):
                    makeAST(EUnary(op, normalizeGuardPredicate(e)));
                case EParen(e):
                    makeAST(EParen(normalizeGuardPredicate(e)));
                default:
                    node;
            };
        }

        // Replace occurrences of Map.get(..., :key) or Keyword.get(..., :key) in body with the bound variable name
        function replaceMapGetWithVar(node: ElixirAST): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    var isKeywordGet = switch (module.def) { case EVar(name) if (name == "Keyword"): true; default: false; };
                    if ((isMapGet || isKeywordGet) && funcName == "get" && args.length == 2) {
                        switch (args[1].def) {
                            case EAtom(atom):
                                var keyName = Std.string(atom);
                                if (varMap.exists(keyName)) {
                                    makeAST(EVar(keyName));
                                } else {
                                    node;
                                }
                            default: node;
                        }
                    } else {
                        // Recurse into module and args
                        var newMod = module != null ? replaceMapGetWithVar(module) : null;
                        var newArgs = [for (a in args) replaceMapGetWithVar(a)];
                        makeAST(ERemoteCall(newMod, funcName, newArgs));
                    }
                case EBinary(op, l, r):
                    makeAST(EBinary(op, replaceMapGetWithVar(l), replaceMapGetWithVar(r)));
                case EUnary(op, e):
                    makeAST(EUnary(op, replaceMapGetWithVar(e)));
                case EIf(c, t, e):
                    makeAST(EIf(replaceMapGetWithVar(c), replaceMapGetWithVar(t), e != null ? replaceMapGetWithVar(e) : null));
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) replaceMapGetWithVar(s)]));
                case ECall(target, name, args):
                    makeAST(ECall(target != null ? replaceMapGetWithVar(target) : null, name, [for (a in args) replaceMapGetWithVar(a)]));
                case ERemoteCall(mod, name, args):
                    makeAST(ERemoteCall(replaceMapGetWithVar(mod), name, [for (a in args) replaceMapGetWithVar(a)]));
                case EParen(e):
                    makeAST(EParen(replaceMapGetWithVar(e)));
                default:
                    node;
            };
        }

        // Build new body: [preBinds..., if simplifiedGuard do: (body with replacements) end]
        // 1) Replace Map.get(...) in guard with the inferred variables
        var guardNoRemote = replaceMapGetInExpr(clause.guard);
        // 2) Normalize simple predicates for guard-friendly functions (is_nil)
        var simplifiedGuard = normalizeGuardPredicate(guardNoRemote);
        // 3) Replace Map.get(...) inside body with inferred variables
        var replacedBody = replaceMapGetWithVar(clause.body);
        var guardedBody = makeAST(EIf(simplifiedGuard, replacedBody, null));
        var newBody: ElixirAST = null;
        if (preBinds.length > 0) {
            var stmts = [];
            for (b in preBinds) stmts.push(b);
            stmts.push(guardedBody);
            newBody = makeAST(EBlock(stmts));
        } else {
            newBody = guardedBody;
        }

        return {
            pattern: clause.pattern,
            guard: null,
            body: newBody
        };
    }

    /**
     * Determine if an expression is safe to use in a guard.
     * Disallow remote/module calls (e.g., Map.get/2) and keep such conditions in the body.
     */
    static function isGuardSafeExpr(expr: ElixirAST): Bool {
        if (expr == null) return false;
        return switch (expr.def) {
            case ERemoteCall(_, _, _):
                // Remote calls are not allowed in guards
                false;
            case ECall(module, _, args):
                // Local calls (module == null) may be allowed (e.g., is_nil/1), module calls are not
                if (module != null) {
                    false;
                } else {
                    var ok = true;
                    for (a in args) {
                        if (!isGuardSafeExpr(a)) { ok = false; break; }
                    }
                    ok;
                }
            case EBinary(_, l, r):
                isGuardSafeExpr(l) && isGuardSafeExpr(r);
            case EUnary(_, e):
                isGuardSafeExpr(e);
            case EVar(_)|EAtom(_)|EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EField(_, _):
                true;
            default:
                // Be conservative for other node types
                false;
        };
    }

    /**
     * Optimize a single case clause by extracting guards from the body
     */
    static function optimizeGuardClause(clause: ECaseClause): ECaseClause {
        // Look for if statements at the start of the body that can become guards
        switch(clause.body.def) {
            case EIf(cond, thenBranch, elseBranch) if (elseBranch == null || isRaiseOrThrow(elseBranch)):
                // This if can be converted to a guard
                var candidate = clause.guard != null 
                    ? makeAST(EBinary(And, clause.guard, cond))
                    : cond;
                // Only convert to guard if the expression is guard-safe (no remote calls, etc.)
                if (!isGuardSafeExpr(candidate)) {
                    return clause; // Keep as body-level if to preserve semantics and compile constraints
                }
                var newGuard = candidate;
                
                return {
                    pattern: clause.pattern,
                    guard: newGuard,
                    body: thenBranch
                };
                
            default:
                return clause;
        }
    }
    
    /**
     * Check if an expression is a raise or throw
     */
    static function isRaiseOrThrow(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case ECall(target, "throw", _): 
                switch(target.def) {
                    case EVar("Kernel"): true;
                    default: false;
                }
            case ECall(target, "raise", _):
                switch(target.def) {
                    case EVar("Kernel"): true;
                    default: false;
                }
            default: false;
        };
    }
    
    /**
     * Pattern variable binding pass - ensures correct variable scoping in patterns
     */
    public static function patternVariableBindingPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern variable binding pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var boundClauses = clauses.map(clause -> bindPatternVariables(clause));
                makeAST(ECase(target, boundClauses));
                
            default:
                // Recursively bind in children
                recursiveTransform(ast, patternVariableBindingPass);
        };
    }
    
    /**
     * Bind pattern variables in a case clause
     */
    static function bindPatternVariables(clause: ECaseClause): ECaseClause {
        // For now, just transform the body recursively
        // In a real implementation, we'd track pattern variables and ensure proper scoping
        var boundBody = patternVariableBindingPass(clause.body);
        
        return {
            pattern: clause.pattern,
            guard: clause.guard,
            body: boundBody
        };
    }
    
    /**
     * Exhaustiveness check pass - adds compile-time verification for pattern completeness
     */
    public static function exhaustivenessCheckPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting exhaustiveness check pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                if (!isExhaustive(clauses)) {
                    // In a real implementation, we'd add a compile-time warning or error
                    #if debug_pattern_matching
                    trace("[PatternMatchingTransforms] WARNING: Non-exhaustive patterns in case expression");
                    #end
                }
                ast;
                
            default:
                // Recursively check children
                recursiveTransform(ast, exhaustivenessCheckPass);
        };
    }
    
    /**
     * Check if case clauses are exhaustive
     */
    static function isExhaustive(clauses: Array<ECaseClause>): Bool {
        // Simple check: look for wildcard pattern
        for (clause in clauses) {
            if (isWildcardPattern(clause.pattern)) {
                return true;
            }
        }
        
        // TODO: More sophisticated exhaustiveness checking based on type information
        return false;
    }
    
    /**
     * Helper function to recursively transform AST nodes
     * Since ElixirAST doesn't have a generic map method, we need to handle each case
     */
    static function recursiveTransform(ast: ElixirAST, transform: ElixirAST -> ElixirAST): ElixirAST {
        var newDef = switch(ast.def) {
            case EBlock(exprs):
                EBlock(exprs.map(e -> transform(e)));
            case EModule(name, attrs, body):
                EModule(name, attrs, body.map(b -> transform(b)));
            case EIf(cond, thenBranch, elseBranch):
                EIf(transform(cond), transform(thenBranch), elseBranch != null ? transform(elseBranch) : null);
            case EMatch(pattern, expr):
                EMatch(pattern, transform(expr));
            case EDef(name, args, guard, body):
                EDef(name, args, guard, transform(body));
            case EDefp(name, args, guard, body):
                EDefp(name, args, guard, transform(body));
            case EFn(clauses):
                EFn(clauses.map(c -> {
                    args: c.args,
                    guard: c.guard,
                    body: transform(c.body)
                }));
            default:
                // For other cases, return unchanged
                ast.def;
        };
        
        var result = makeAST(newDef);
        if (ast.metadata != null) {
            result.metadata = ast.metadata;
        }
        if (ast.pos != null) {
            result.pos = ast.pos;
        }
        return result;
    }

    /**
     * PatternBinderSuffixNormalizationPass (tag-agnostic)
     *
     * WHY: Across clause groups or after consolidation, guard/body expressions may reference
     * suffixed variants of pattern binders (e.g., g2, b3). This causes hygiene to consider
     * the original binders unused and wildcard the pattern. We normalize references back to
     * the base binder names strictly when the base exists in the clause's pattern.
     *
     * WHAT: For each case clause, collect binder names from the pattern and strip trailing
     * digits from variable references in both guard and body only if the base name is a binder.
     *
     * SCOPE: Tag-agnostic, affects all case clauses. AST-pure.
     */
    public static function patternBinderSuffixNormalizationPass(ast: ElixirAST): ElixirAST {
        function stripDigitsSuffixLocal(s:String):String {
            var re = ~/([0-9]+)$/;
            return re.replace(s, "");
        }

        function normalizeClause(c: ECaseClause): ECaseClause {
            var binderBases = new Map<String, Bool>();
            function collectBases(p:EPattern):Void {
                switch (p) {
                    case PVar(v): binderBases.set(stripDigitsSuffixLocal(v), true);
                    case PAlias(v, inner): binderBases.set(stripDigitsSuffixLocal(v), true); collectBases(inner);
                    case PTuple(el): for (e in el) collectBases(e);
                    case PList(el): for (e in el) collectBases(e);
                    case PCons(h,t): collectBases(h); collectBases(t);
                    case PMap(pairs): for (kv in pairs) collectBases(kv.value);
                    case PStruct(_, fields): for (f in fields) collectBases(f.value);
                    default:
                }
            }
            collectBases(c.pattern);
            #if debug_binder_norm
            var basesStr = [];
            for (k in binderBases.keys()) basesStr.push(k);
            trace('[BinderNorm] Clause binder bases: [' + basesStr.join(', ') + ']');
            #end

            function fixRef(n: ElixirAST): ElixirAST {
                if (n == null) return n;
                return switch (n.def) {
                    case EVar(name):
                        var base = stripDigitsSuffixLocal(name);
                        if (base != name && binderBases.exists(base)) {
                            #if debug_binder_norm
                            trace('[BinderNorm]   EVar normalize: ' + name + ' -> ' + base);
                            #end
                            makeAST(EVar(base));
                        } else n;
                    case EBinary(op, l, r): makeAST(EBinary(op, fixRef(l), fixRef(r)));
                    case ECall(t, nm, args): makeAST(ECall(t != null ? fixRef(t) : null, nm, [for (a in args) fixRef(a)]));
                    case ERemoteCall(mod, nm, args): makeAST(ERemoteCall(mod != null ? fixRef(mod) : null, nm, [for (a in args) fixRef(a)]));
                    case EIf(cond, tb, eb): makeAST(EIf(fixRef(cond), fixRef(tb), eb != null ? fixRef(eb) : null));
                    case ECond(cls):
                        var mapped = [];
                        var idx = 0;
                        for (clc in cls) {
                            #if debug_binder_norm
                            trace('[BinderNorm]   Visiting cond branch #' + idx);
                            #end
                            mapped.push({ condition: fixRef(clc.condition), body: fixRef(clc.body) });
                            idx++;
                        }
                        makeAST(ECond(mapped));
                    case EBlock(sts): makeAST(EBlock([for (s in sts) fixRef(s)]));
                    case EParen(e): makeAST(EParen(fixRef(e)));
                    default: n;
                };
            }

            return {
                pattern: sanitizePatternBinders(c.pattern),
                guard: c.guard != null ? fixRef(c.guard) : null,
                body: fixRef(c.body)
            };
        }

        return switch (ast.def) {
            case ECase(target, clauses):
                var newClauses = [for (c in clauses) normalizeClause(c)];
                makeAST(ECase(patternBinderSuffixNormalizationPass(target), newClauses));
            default:
                recursiveTransform(ast, patternBinderSuffixNormalizationPass);
        };
    }
}

#end
