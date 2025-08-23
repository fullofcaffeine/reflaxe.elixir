class TestLoop {
    public static function main() {
        var obj = {a: 1, b: 2};
        for (field in Reflect.fields(obj)) {
            trace(field);
        }
    }
}