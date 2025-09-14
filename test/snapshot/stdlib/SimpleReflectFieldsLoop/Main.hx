class Main {
    static function main() {
        var obj: Dynamic = {
            a: 1,
            b: 2,
            c: 3
        };
        
        // Simple for loop over Reflect.fields
        for (key in Reflect.fields(obj)) {
            trace(key);
        }
    }
}