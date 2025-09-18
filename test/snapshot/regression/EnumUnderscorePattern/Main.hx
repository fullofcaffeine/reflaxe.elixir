package;

enum HttpStatus {
    Ok;
    Custom(code: Int);
    Error(msg: String);
    Redirect(url: String, permanent: Bool);
}

class Main {
    static function main() {
        // Test basic enum with underscore patterns
        var status1 = Custom(404);
        var code1 = toInt(status1);
        trace('Custom(404) -> ${code1}');

        var status2 = Ok;
        var code2 = toInt(status2);
        trace('Ok -> ${code2}');

        // Test with underscore-prefixed parameter names
        var status3 = Error("Not Found");
        var msg = getMessage(status3);
        trace('Error message: ${msg}');

        // Test multiple parameters
        var status4 = Redirect("/home", true);
        var info = getRedirectInfo(status4);
        trace('Redirect: ${info}');
    }

    static function toInt(status: HttpStatus): Int {
        return switch(status) {
            case Ok: 200;
            case Custom(code): code;  // Should extract 'code' properly, not generate (g)
            case Error(_): 500;
            case Redirect(_, _): 301;
        };
    }

    static function getMessage(status: HttpStatus): String {
        return switch(status) {
            case Ok: "Success";
            case Custom(_code): "Custom status";  // Underscore prefix - should be handled
            case Error(msg): msg;
            case Redirect(url, _): 'Redirecting to ${url}';
        };
    }

    static function getRedirectInfo(status: HttpStatus): String {
        return switch(status) {
            case Redirect(url, permanent):
                'URL: ${url}, Permanent: ${permanent}';
            case _:
                "Not a redirect";
        };
    }
}