import reflaxe.elixir.helpers.NamingHelper;

class TestNaming {
    public static function main() {
        var result = NamingHelper.toSnakeCase("getStatusClass");
        trace('getStatusClass -> ${result}');
        
        var result2 = NamingHelper.toSnakeCase("getStatusText");
        trace('getStatusText -> ${result2}');
    }
}