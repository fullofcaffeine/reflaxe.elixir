import HXX;
import haxe.extern.EitherType;

typedef CardAssigns = {
    label: EitherType<String, Bool>,
    inner_content: String
}

@:component
class Components {
    @:component
    public static function card(assigns: CardAssigns): String {
        return hxx('<div>${assigns.label}${assigns.inner_content}</div>');
    }
}

class Main {
    public static function render(assigns: {}): String {
        // Should fail: EitherType<String, Bool> does not accept Int.
        return hxx('<.card label=${123}>Hi</.card>');
    }

    public static function main(): Void {}
}

