package;

enum Status {
    Ok;
    Error(msg: String);
    Custom(code: Int);
}

class Main {
    public static function main() {
        var result = toInt(Custom(418));
        trace(result);
    }
    
    public static function toInt(status: Status): Int {
        return switch(status) {
            case Ok: 200;
            case Error(msg): 500; // msg is unused
            case Custom(code): code; // code is USED - returned directly
        };
    }
}