enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class Main {
    static function main() {
        var result: Result<String, String> = Error("test");
        
        switch(result) {
            case Error(changeset):
                var errors = changeset + " processed";
                trace('Changeset validation failed: $errors');
        }
    }
}