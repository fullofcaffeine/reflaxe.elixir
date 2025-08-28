class Main {
    public static function main() {
        var obj = {a: 1, b: 2, c: 3};
        
        // Simple for-in loop over Reflect.fields
        for (field in Reflect.fields(obj)) {
            trace('Field: $field');
        }
        
        // Nested loops with Reflect.fields  
        var data = {errors: {name: ["Required"], age: ["Invalid"]}};
        var changesetErrors = Reflect.field(data, "errors");
        if (changesetErrors != null) {
            for (field in Reflect.fields(changesetErrors)) {
                var fieldErrors = Reflect.field(changesetErrors, field);
                if (Std.isOfType(fieldErrors, Array)) {
                    for (error in cast(fieldErrors, Array<Dynamic>)) {
                        trace('${field}: ${error}');
                    }
                }
            }
        }
    }
}