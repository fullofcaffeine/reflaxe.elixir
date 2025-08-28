package;

/**
 * Test for Ecto error reporting validation
 * This test intentionally contains errors to validate error messages
 */

@:schema
class InvalidSchema {
    // Field with reserved keyword as name (should trigger warning)
    @:field({type: "string", defaultValue: "test"})
    public var validField: String;
    
    // Field with invalid type
    @:field({type: "invalid_type"})
    public var invalidTypeField: String;
}

@:changeset
class InvalidChangeset {
    // Missing static changeset function (should trigger error)
    public function new() {}
}

class Main {
    static function main() {
        trace("Ecto error validation test");
    }
}