package;

typedef Assigns = {
    var count: Int;
}

class Main {
    public static function render(assigns: Assigns): String {
        return <div class="counter">
          <h1>${assigns.count}</h1>
          <button phx-click="increment">+</button>
        </div>;
    }

    public static function main() {}
}

