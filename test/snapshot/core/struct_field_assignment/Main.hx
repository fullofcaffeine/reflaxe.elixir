class TestStruct {
    public var field: String;
    
    public function new() {
        this.field = "";
    }
    
    public function write(value: Dynamic): Void {
        switch (Type.typeof(value)) {
            case TNull:
                this.field = this.field + "null";
            case TInt:
                this.field = this.field + Std.string(value);
            default:
                this.field = this.field + "other";
        }
    }
}

class Main {
    static function main() {
        var test = new TestStruct();
        test.write(null);
    }
}