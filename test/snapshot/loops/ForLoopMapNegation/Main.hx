typedef Error = {
    field: String,
    message: String
}

typedef Changeset = {
    errors: Array<Error>
}

class Main {
    static function main() {
        var changeset: Changeset = {
            errors: [
                {field: "name", message: "required"},
                {field: "email", message: "invalid"},
                {field: "name", message: "too short"}
            ]
        };
        
        var errorMap = getErrorsMap(changeset);
        trace("Errors: " + errorMap);
    }
    
    static function getErrorsMap(changeset: Changeset): Map<String, Array<String>> {
        var errorMap = new Map<String, Array<String>>();
        
        for (error in changeset.errors) {
            if (!errorMap.exists(error.field)) {
                errorMap.set(error.field, []);
            }
            errorMap.get(error.field).push(error.message);
        }
        
        return errorMap;
    }
}