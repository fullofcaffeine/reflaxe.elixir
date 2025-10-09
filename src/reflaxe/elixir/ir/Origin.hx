package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)
enum Origin {
    UserDefined;
    PatternBinder;
    Temp;
}
#end

