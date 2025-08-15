import reflaxe.elixir.HXX;

class TestHXX {
    public static function main() {
        var name = "World";
        var template = HXX.hxx('<div>Hello ${name}!</div>');
        trace(template);
    }
}
