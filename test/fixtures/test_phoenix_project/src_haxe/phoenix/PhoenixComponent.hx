package phoenix;

class PhoenixComponent {
    public static function main() {
        trace("Phoenix integration working!");
    }
    
    public static function render(): String {
        return "<div>Hello from Haxe component!</div>";
    }
}
