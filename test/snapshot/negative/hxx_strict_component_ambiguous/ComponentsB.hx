package;

import HXX;

typedef CardAssignsB = {
    var title: String;
    var inner_content: String;
}

@:native("Test.ComponentsB")
@:component
class ComponentsB {
    @:component
    public static function card(assigns: CardAssignsB): String {
        return HXX.hxx('<div><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
    }
}
