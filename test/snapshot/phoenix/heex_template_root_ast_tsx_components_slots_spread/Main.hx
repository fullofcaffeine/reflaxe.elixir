package;

typedef User = {
    var name: String;
}

typedef Assigns = {
    var attrs: Map<String, String>;
    var users: Array<User>;
    var title: String;
}

@:liveview
@:hxx_mode("tsx")
class Main {
    public static function render(assigns: Assigns): String {
        return <section {assigns.attrs} data-testid="users">
            <.panel title={assigns.title}>
                <:actions>
                    <.button class="btn">New</.button>
                </:actions>

                <ul>
                    <for ${user in assigns.users}>
                        <li>${user.name}</li>
                    </for>
                </ul>
            </.panel>

            <Main.Components.badge {@assigns.attrs} />
        </section>;
    }

    public static function main() {}
}
