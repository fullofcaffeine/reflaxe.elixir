package;

/**
 * Ecto schema auto changeset generation test
 *
 * WHAT
 * - Verify that when no changeset/2 is provided, the compiler emits a default
 *   changeset using `cast(attrs, [:field_atoms])` followed by validate_required when applicable.
 */
@:schema
class Post {
    public var title: String;
    public var description: String;
    public var published: Bool;
    public var dueDate: Null<Date>;
}

