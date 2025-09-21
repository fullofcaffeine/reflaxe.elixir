enum Result<T> {
    Ok(value: T);
    Error(msg: String);
}

class DebugEnum {
    static function main() {
        var result = Ok("test");
        switch(result) {
            case Ok(value):
                trace(value);
            case Error(msg):
                trace(msg);
        }
    }
}