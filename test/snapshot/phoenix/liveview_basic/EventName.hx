package;

@:phxEventNames
enum abstract EventName(String) from String to String {
    var Increment = "increment";
    var Decrement = "decrement";
}

