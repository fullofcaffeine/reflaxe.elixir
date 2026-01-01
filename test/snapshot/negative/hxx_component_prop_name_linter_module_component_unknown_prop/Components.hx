package;

import HXX;

typedef CardAssigns = {
    var title: String;
    ?className: String;
    var inner_content: String;
}

@:native("Test.Components")
@:component
class Components {
    @:component
    public static function card(assigns: CardAssigns): String {
        return HXX.hxx('<div class=${assigns.className}><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
    }
}

