class TestLoopDebug {
    public static function main() {
        var items = [];
        for (i in 0...5) {
            items.push("Item " + i);
        }
        trace(items);
    }
}