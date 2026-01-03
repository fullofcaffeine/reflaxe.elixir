package;

import HXX;

typedef CardAssignsB = {
    var headline: String;
    var inner_content: String;
}

@:native("AppBWeb.CoreComponents")
@:component
class CoreComponentsB {
    @:component
    public static function card(assigns: CardAssignsB): String {
        return HXX.hxx('<div><h2>${assigns.headline}</h2>${assigns.inner_content}</div>');
    }
}
