enum Result<T> {
    Ok(value: T);
    Error(msg: String);
}

class Main {
    public static function main(): Void {
        var result: Result<String> = Ok("test");
        switch(result) {
            case Ok(value):
                trace(value);
            case Error(msg):
                trace("Error: " + msg);
        }
    }
}