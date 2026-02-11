package;

typedef Assigns = {
    var show: Bool;
}

@:liveview
@:hxx_mode("tsx")
class Main {
    public static function render(assigns: Assigns): String {
        return <div data-testid="if-attrs">
            <button :if ${assigns.show} class="plain">Visible</button>
            <button :if=${assigns.show} class="equals">Also Visible</button>
        </div>;
    }

    public static function main() {}
}
