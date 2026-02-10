package;

typedef Assigns = {
    var enabled: Bool;
    var count: Int;
}

@:liveview
class Main {
    public static function render(assigns: Assigns): String {
        return <div class="chip ${assigns.enabled ? "is-on" : "is-off"}" data-count=${assigns.count}>
          <span class="label">Hello</span>
        </div>;
    }

    public static function main() {}
}

