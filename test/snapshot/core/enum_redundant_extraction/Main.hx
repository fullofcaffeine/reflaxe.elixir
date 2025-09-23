enum MessageType {
    Created(content: String);
    Updated(id: String, content: String);
    Deleted(id: String);
}

class Main {
    static function main() {
        var msg = Created("Hello world");

        // Test single parameter enum extraction
        switch(msg) {
            case Created(content):
                trace("Created: " + content);
            case Updated(id, content):
                trace("Updated " + id + ": " + content);
            case Deleted(id):
                trace("Deleted: " + id);
        }

        // Test with Result-like enum
        var result = Result.Ok("success");
        switch(result) {
            case Ok(value):
                trace("Success: " + value);
            case Error(err):
                trace("Error: " + err);
        }
    }
}

enum Result<T> {
    Ok(value: T);
    Error(msg: String);
}