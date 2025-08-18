class TestElixir {
    public static function main() {
        var result = untyped __elixir__("DateTime.utc_now()");
        trace(result);
    }
}
