package;

import phoenix.hxx.HeexTemplate;

typedef Item = {
    var name: String;
}

typedef Assigns = {
    var show: Bool;
    var items: Array<Item>;
}

@:liveview
class Main {
    public static function render(assigns: Assigns): String {
        return <div class="root">
            ${if (assigns.show) <span class="yes">Yes</span> else <span class="no">No</span>}
            <ul>
                ${HeexTemplate.for_each(assigns.items, (item) -> <li>${item.name}</li>)}
            </ul>
        </div>;
    }

    public static function main() {}
}

