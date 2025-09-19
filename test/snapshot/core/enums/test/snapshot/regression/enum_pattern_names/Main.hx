// Regression test for enum pattern variable names
// Issue: Patterns were using temp vars (g, g1, g2) instead of proper names
// This caused undefined variable errors in generated Elixir

enum Status {
    Success(data: String);
    Error(message: String, code: Int);
    Processing;
}

class Main {
    public static function handleStatus(status: Status): String {
        return switch (status) {
            case Success(data):
                // Should compile to {:success, data} not {:success, g}
                "Data: " + data;
            case Error(message, code):
                // Should compile to {:error, message, code} not {:error, g, g1}
                "Error " + code + ": " + message;
            case Processing:
                "Still processing...";
        }
    }

    public static function main() {
        trace(handleStatus(Success("test data")));
        trace(handleStatus(Error("not found", 404)));
        trace(handleStatus(Processing));
    }
}
