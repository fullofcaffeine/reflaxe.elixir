package;

import HXX;
import phoenix.types.Slot;

typedef HeaderSlotProps = {
    var label: String;
}

typedef HeaderLet = {
    var count: Int;
    var userName: String;
}

typedef CardAssigns = {
    var title: String;
    @:slot var header: Slot<HeaderSlotProps, HeaderLet>;
    var inner_content: String;
}

@:native("Test.Components")
@:component
class Components {
    @:component
    public static function card(assigns: CardAssigns): String {
        return HXX.hxx('<div><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
    }
}

