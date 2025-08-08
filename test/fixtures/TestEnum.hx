package fixtures;

/**
 * Test enum definitions for validation
 */

// Simple enum - should compile to atoms
enum SimpleStatus {
    None;
    Ready;
    Error;
}

// Parameterized enum - should compile to tagged tuples
enum Result<T> {
    Success(value: T);
    Failure(error: String);
}

// Mixed enum with simple and parameterized options
enum Message {
    Info(text: String);
    Warning(text: String, level: Int);
    Critical;
}

// Option enum - common Haxe pattern
enum Option<T> {
    None;
    Some(value: T);
}