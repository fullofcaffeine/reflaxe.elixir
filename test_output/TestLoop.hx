class TestLoop {
    public static function main() {
        var obj = {errors: {name: ["Required"]}};
        var changesetErrors = Reflect.field(obj, "errors");
        if (changesetErrors != null) {
            for (field in Reflect.fields(changesetErrors)) {
                trace(field);
            }
        }
    }
}
