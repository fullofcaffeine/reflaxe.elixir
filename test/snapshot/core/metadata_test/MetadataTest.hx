// Test metadata with complex object syntax
@:schema("users")
class User {
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "integer", defaultValue: 0})
    public var age: Int;
    
    @:field({type: "decimal", precision: 10, scale: 2})
    public var balance: Float;
    
    public static function main() {
        trace("Testing complex metadata syntax");
    }
}