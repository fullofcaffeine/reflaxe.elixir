package;

typedef Item = {
    var name: String;
}

typedef Assigns = {
    var count: Int;
    var items: Array<Item>;
    var show: Bool;
    var klass: String;
}

@:liveview
@:hxx_mode("tsx")
class Main {
    public static function render(assigns: Assigns): String {
        return <div class="wrap ${assigns.klass}">
            <h1>${assigns.count}</h1>

            <if ${assigns.show}>
                <span class="yes">yes</span>
            <else>
                <span class="no">no</span>
            </else>
            </if>

            <ul>
                <for ${item in assigns.items}>
                    <li class="row ${item.name}">${item.name}</li>
                </for>
            </ul>
        </div>;
    }

    public static function main() {}
}
