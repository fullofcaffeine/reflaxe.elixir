import ecto.Changeset;

typedef UserParams = {
    var name: String;
    var email: String;
}

@:schema("users")
@:changeset(["name", "email"], ["name", "email"])
class User {
    public function new() {}

    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
}

class Main {
    static function main() {
        var params: UserParams = {name: "Ada", email: "ada@example.com"};
        var changeset: Changeset<User, UserParams> = User.changeset(new User(), params);
        trace(changeset);
    }
}
