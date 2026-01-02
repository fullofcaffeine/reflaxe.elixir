package;

import HXX;
import phoenix.types.Slot;
import elixir.types.Term;

typedef CardAssigns = {
    var title: String;
    @:slot var inner_block: Slot<Term>;
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

