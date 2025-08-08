package phoenix;

/**
 * Example Ecto Schema for User model
 * Tests schema generation and Ecto integration
 */
@:schema("users")
class User {
    
    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
    @:field public var age: Null<Int>;
    @:field public var is_active: Bool = true;
    @:field public var inserted_at: Dynamic;
    @:field public var updated_at: Dynamic;
    
    /**
     * Required fields for validation
     */
    static var required_fields = ["name", "email"];
    
    /**
     * Optional fields that can be cast
     */
    static var optional_fields = ["age", "is_active"];
    
    /**
     * Constructor for creating new User instances
     */
    public function new(?attrs: Dynamic) {
        if (attrs != null) {
            if (attrs.name != null) this.name = attrs.name;
            if (attrs.email != null) this.email = attrs.email;
            if (attrs.age != null) this.age = attrs.age;
            if (attrs.is_active != null) this.is_active = attrs.is_active;
        }
    }
    
    /**
     * Changeset for creating and updating users
     * This would compile to proper Ecto.Changeset operations
     */
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        // This would compile to:
        // user
        // |> cast(attrs, @required_fields ++ @optional_fields)
        // |> validate_required(@required_fields)
        // |> validate_format(:email, ~r/@/)
        // |> unique_constraint(:email)
        
        var changeset = Ecto.Changeset.cast(user, attrs, required_fields.concat(optional_fields));
        changeset = Ecto.Changeset.validate_required(changeset, required_fields);
        changeset = Ecto.Changeset.validate_format(changeset, "email", ~/@/);
        changeset = Ecto.Changeset.unique_constraint(changeset, "email");
        
        return changeset;
    }
    
    /**
     * Changeset for user registration with additional validations
     */
    public static function registration_changeset(user: User, attrs: Dynamic): Dynamic {
        var changeset = changeset(user, attrs);
        
        // Additional validations for registration
        changeset = Ecto.Changeset.validate_length(changeset, "name", {min: 2, max: 50});
        changeset = Ecto.Changeset.validate_format(changeset, "email", ~/^[^\s]+@[^\s]+\.[^\s]+$/);
        
        return changeset;
    }
    
    /**
     * Check if user is an adult
     */
    public function is_adult(): Bool {
        return age != null && age >= 18;
    }
    
    /**
     * Get user display name
     */
    public function display_name(): String {
        return name != null ? name : "Anonymous";
    }
}