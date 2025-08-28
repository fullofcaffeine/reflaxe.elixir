package;

/**
 * Changeset compiler test case
 * Tests @:changeset annotation compilation
 */
@:changeset
class User {
	public var name: String;
	public var email: String;
	public var age: Int;
	public var bio: String;
	
	// Validation rules
	@:validate_required(["name", "email"])
	@:validate_length("bio", {min: 10, max: 500})
	@:validate_number("age", {greater_than: 0, less_than: 150})
	@:validate_format("email", ~/@/)
	public function changeset(user: User, params: Dynamic): Dynamic {
		// The compiler will generate the actual changeset pipeline
		return null;
	}
	
	// Custom validation
	public function validate_email_domain(changeset: Dynamic): Dynamic {
		// Custom validation logic
		return changeset;
	}
	
	// Another changeset for updates
	@:validate_required(["name"])
	@:validate_length("bio", {min: 10})
	public function update_changeset(user: User, params: Dynamic): Dynamic {
		return null;
	}
}