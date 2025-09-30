class Main {
    static function main() {
        // Test 1: Variable assigned then used immediately
        var changeset = getChangeset();
        trace(changeset);

        // Test 2: Variable assigned then used in condition
        var user = getUser();
        if (user == null) {
            trace("No user");
        }
        trace(user);

        // Test 3: Variable assigned then used as return value
        var result = compute();
        trace(result);
    }

    static function getChangeset(): Dynamic {
        return "changeset_data";
    }

    static function getUser(): Dynamic {
        return "user_data";
    }

    static function compute(): String {
        return "computed";
    }
}