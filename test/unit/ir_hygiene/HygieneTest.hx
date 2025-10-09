package test.unit.ir_hygiene;

#if reflaxe_runtime
import reflaxe.elixir.ir.Symbol;
import reflaxe.elixir.ir.Scope;
import reflaxe.elixir.ir.Hygiene;
import reflaxe.elixir.ir.Origin;
import reflaxe.elixir.ir.ScopeKind;

class HygieneTest {
    static function main() {
        var scopes = [
            new Scope(1, ScopeKind.Function, null),
            new Scope(2, ScopeKind.Block, 1)
        ];
        var symbols = [
            new Symbol(1, "r", 1, Origin.PatternBinder, true),
            new Symbol(2, "g", 1, Origin.PatternBinder, true),
            new Symbol(3, "b", 1, Origin.PatternBinder, true),
            new Symbol(4, "when", 1, Origin.UserDefined, true),
            new Symbol(5, "tmpValue", 1, Origin.Temp, false),
            new Symbol(6, "r", 2, Origin.UserDefined, true) // shadow in block
        ];
        var names = Hygiene.computeFinalNames(symbols, scopes);
        // Print to verify deterministic mapping visually (compile/run ok path)
        for (s in symbols) {
            var n = names.get(s);
            if (n == null) n = "<none>";
            #if neko
            neko.Lib.print(s.id + ":" + n + "\n");
            #elseif sys
            Sys.print(s.id + ":" + n + "\n");
            #end
        }
    }
}
#else
class HygieneTest { static function main() {} }
#end
