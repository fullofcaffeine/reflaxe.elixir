package;

import HXX;

typedef CardAssignsA = {
    var title: String;
    var inner_content: String;
}

@:native("Test.ComponentsA")
@:component
class ComponentsA {
    @:component
    public static function card(assigns: CardAssignsA): String {
        return HXX.hxx('<div><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
    }
}
