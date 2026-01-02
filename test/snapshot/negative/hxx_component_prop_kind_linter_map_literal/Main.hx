import HXX;

typedef CardAssigns = {
    title: String,
    inner_content: String
}

@:component
class Components {
    @:component
    public static function card(assigns: CardAssigns): String {
        return hxx('<div>${assigns.title}${assigns.inner_content}</div>');
    }
}

class Main {
    public static function render(assigns: {}): String {
        return hxx('<.card title=${{foo: "bar"}}>Hi</.card>');
    }

    public static function main(): Void {}
}

