package;

typedef Assigns = {
    var count: Int;
}

@:liveview
class Main {
    public static function render(assigns: Assigns): String {
        var template = <div class="counter">
          <h1>${assigns.count}</h1>
        </div>;
        return template;
    }

    public static function main() {}
}

