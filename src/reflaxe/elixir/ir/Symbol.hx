package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ir.ScopeId;
import reflaxe.elixir.ir.Origin;

class Symbol {
    public var id:Int;
    public var suggestedName:String;
    public var scope:ScopeId;
    public var used:Bool;
    public var origin:Origin;
    public function new(id:Int, suggestedName:String, scope:ScopeId, origin:Origin, used:Bool=false) {
        this.id = id;
        this.suggestedName = suggestedName;
        this.scope = scope;
        this.origin = origin;
        this.used = used;
    }
}

#end
