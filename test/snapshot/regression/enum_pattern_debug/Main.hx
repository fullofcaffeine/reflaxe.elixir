package;

enum Result<T> {
    Error(changeset: T);
    Ok(value: T);
}

class Main {
    public static function main() {
        var result: Result<String> = Error("validation_failed");
        
        switch(result) {
            case Error(changeset): 
                var errors = changeset + "_processed";
                trace('Changeset validation failed: $errors');
            case Ok(value):
                trace('Success: $value');
        }
    }
}