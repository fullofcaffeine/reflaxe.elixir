package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)
enum ScopeKind {
    Module;
    Function;
    Case;
    Fn;
    Block;
}
#end

