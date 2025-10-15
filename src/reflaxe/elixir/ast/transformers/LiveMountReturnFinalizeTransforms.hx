package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * LiveMountReturnFinalizeTransforms
 *
 * WHAT
 * - Ensures Phoenix.LiveView mount/3 functions return an {:ok, socket} tuple by
 *   synthesizing a final tuple when missing. If a map of assigns is present and there
 *   is no prior assign/2 call, wraps the tuple value with Phoenix.Component.assign(socket, assigns).
 *
 * WHY
 * - Some generation paths leave mount/3 ending with a bare assigns map or without
 *   a final tuple, triggering WAE and runtime failures. This pass corrects only the
 *   return shape based on structural cues — no app-specific naming heuristics beyond
 *   the conventional socket parameter position.
 *
 * HOW
 * - Targets EDef("mount", args, _, EBlock/EDo):
 *   - Determine socket parameter name from the last function parameter when it is a PVar.
 *   - Detect any local variable bound to an EMap literal in the function body (candidate assignsVar).
 *   - If the function already ends with an ETuple {:ok, _}, leave it unchanged.
 *   - Otherwise, append a final ETuple {:ok, socketOrAssigned} where socketOrAssigned is:
 *       Phoenix.Component.assign(socketParam, assignsVar) when assignsVar exists;
 *       otherwise, the socketParam unchanged.
 *   - Does not introduce temporary variables; uses inline call for determinism.
 *
 * EXAMPLES
 * Before:
 *   assigns = %{...}
 *   # no return
 * After:
 *   assigns = %{...}
 *   {:ok, Phoenix.Component.assign(socket, assigns)}
 */
class LiveMountReturnFinalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "mount"):
                    var socketParam: Null<String> = null;
                    if (args != null && args.length > 0) {
                        // Prefer the last parameter name for socket (mount/3 -> third param)
                        var last = args[args.length - 1];
                        switch (last) { case PVar(nm): socketParam = nm; default: }
                    }
                    if (socketParam == null) return n;

                    switch (body.def) {
                        case EBlock(stmts):
                            var alreadyTuple = false;
                            if (stmts.length > 0) switch (stmts[stmts.length - 1].def) {
                                case ETuple(elems) if (elems.length == 2):
                                    alreadyTuple = (switch (elems[0].def) { case EAtom(_): true; default: false; });
                                default:
                            }
                            if (alreadyTuple) return n;
                            // If the final statement is `var = %{} (map literal)`, replace it with {:ok, assign(socket, %{})}
                            if (stmts.length > 0) switch (stmts[stmts.length - 1].def) {
                                case EBinary(Match, leftAny, rhs):
                                    switch (rhs.def) {
                                        case EMap(_):
                                            var okAtom0 = makeAST(EAtom(ElixirAtom.raw("ok")));
                                            var tupleVal0 = makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), rhs]));
                                            var finalTuple0 = makeAST(ETuple([okAtom0, tupleVal0]));
                                            var replaced:Array<ElixirAST> = stmts.copy();
                                            replaced[replaced.length - 1] = finalTuple0;
                                            #if debug_live_mount
                                            Sys.println('[LiveMountReturnFinalize] Replaced trailing map assignment with {:ok, assign(socket, %{})} in mount/3');
                                            #end
                                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(replaced))), n.metadata, n.pos);
                                        default:
                                    }
                                case EMatch(patAny, rhsM):
                                    switch (rhsM.def) {
                                        case EMap(_):
                                            var okAtomM = makeAST(EAtom(ElixirAtom.raw("ok")));
                                            var tupleValM = makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), rhsM]));
                                            var finalTupleM = makeAST(ETuple([okAtomM, tupleValM]));
                                            var replacedM:Array<ElixirAST> = stmts.copy();
                                            replacedM[replacedM.length - 1] = finalTupleM;
                                            #if debug_live_mount
                                            Sys.println('[LiveMountReturnFinalize] Replaced trailing match map assignment with {:ok, assign(socket, %{})} in mount/3');
                                            #end
                                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(replacedM))), n.metadata, n.pos);
                                        default:
                                    }
                                default:
                            }
                            // Discover a local var bound to an EMap literal to use as assigns var
                            var assignsVar: Null<String> = null;
                            for (s in stmts) switch (s.def) {
                                case EBinary(Match, left, rhs):
                                    switch (left.def) { case EVar(v):
                                        switch (rhs.def) { case EMap(_): assignsVar = v; default: }
                                    default: }
                                case EMatch(pat, rhs2):
                                    switch (pat) { case PVar(v2):
                                        switch (rhs2.def) { case EMap(_): assignsVar = v2; default: }
                                    default: }
                                default:
                            }
                            var okAtom = makeAST(EAtom(ElixirAtom.raw("ok")));
                            var tupleVal: ElixirAST = (assignsVar != null)
                                ? makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), makeAST(EVar(assignsVar))]))
                                : makeAST(EVar(socketParam));
                            var finalTuple = makeAST(ETuple([okAtom, tupleVal]));
                            #if debug_live_mount
                            Sys.println('[LiveMountReturnFinalize] Appended {:ok, ...} to mount/3');
                            #end
                            var out:Array<ElixirAST> = stmts.copy();
                            out.push(finalTuple);
                            makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(out))), n.metadata, n.pos);

                        case EDo(stmts2):
                            var alreadyTuple2 = false;
                            if (stmts2.length > 0) switch (stmts2[stmts2.length - 1].def) {
                                case ETuple(elems) if (elems.length == 2):
                                    alreadyTuple2 = (switch (elems[0].def) { case EAtom(_): true; default: false; });
                                default:
                            }
                            if (alreadyTuple2) return n;
                            // Replace trailing map assignment with tuple using inline map in assign/2
                            if (stmts2.length > 0) switch (stmts2[stmts2.length - 1].def) {
                                case EBinary(Match, leftAny2, rhs2):
                                    switch (rhs2.def) {
                                        case EMap(_):
                                            var okAtomX = makeAST(EAtom(ElixirAtom.raw("ok")));
                                            var tupleValX = makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), rhs2]));
                                            var finalTupleX = makeAST(ETuple([okAtomX, tupleValX]));
                                            var replaced2:Array<ElixirAST> = stmts2.copy();
                                            replaced2[replaced2.length - 1] = finalTupleX;
                                            #if debug_live_mount
                                            Sys.println('[LiveMountReturnFinalize] Replaced trailing map assignment with {:ok, assign(socket, %{})} in mount/3 (EDo)');
                                            #end
                                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(replaced2))), n.metadata, n.pos);
                                        default:
                                    }
                                case EMatch(patAny2, rhsM2):
                                    switch (rhsM2.def) {
                                        case EMap(_):
                                            var okAtomY = makeAST(EAtom(ElixirAtom.raw("ok")));
                                            var tupleValY = makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), rhsM2]));
                                            var finalTupleY = makeAST(ETuple([okAtomY, tupleValY]));
                                            var replacedY:Array<ElixirAST> = stmts2.copy();
                                            replacedY[replacedY.length - 1] = finalTupleY;
                                            #if debug_live_mount
                                            Sys.println('[LiveMountReturnFinalize] Replaced trailing match map assignment with {:ok, assign(socket, %{})} in mount/3 (EDo)');
                                            #end
                                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(replacedY))), n.metadata, n.pos);
                                        default:
                                    }
                                default:
                            }
                            var assignsVar2: Null<String> = null;
                            for (s in stmts2) switch (s.def) {
                                case EBinary(Match, left, rhs):
                                    switch (left.def) { case EVar(v):
                                        switch (rhs.def) { case EMap(_): assignsVar2 = v; default: }
                                    default: }
                                case EMatch(pat, rhs2):
                                    switch (pat) { case PVar(v2):
                                        switch (rhs2.def) { case EMap(_): assignsVar2 = v2; default: }
                                    default: }
                                default:
                            }
                            var okAtom2 = makeAST(EAtom(ElixirAtom.raw("ok")));
                            var tupleVal2: ElixirAST = (assignsVar2 != null)
                                ? makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [makeAST(EVar(socketParam)), makeAST(EVar(assignsVar2))]))
                                : makeAST(EVar(socketParam));
                            var finalTuple2 = makeAST(ETuple([okAtom2, tupleVal2]));
                            #if debug_live_mount
                            Sys.println('[LiveMountReturnFinalize] Appended {:ok, ...} to mount/3 (EDo)');
                            #end
                            var out2:Array<ElixirAST> = stmts2.copy();
                            out2.push(finalTuple2);
                            makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(out2))), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
