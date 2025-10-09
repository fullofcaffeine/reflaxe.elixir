package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ir.ScopeId;
import reflaxe.elixir.ir.ScopeKind;

class Scope {
    public var id:ScopeId;
    public var parent:Null<ScopeId>;
    public var kind:ScopeKind;
    public function new(id:ScopeId, kind:ScopeKind, ?parent:ScopeId) {
        this.id = id;
        this.kind = kind;
        this.parent = parent;
    }
}
#end

