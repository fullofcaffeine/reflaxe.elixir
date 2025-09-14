/**
 * Regression test for struct field concatenation fix
 *
 * Ensures that array.push() operations on struct fields generate
 * proper struct updates instead of bare concatenations that cause
 * Elixir compilation warnings.
 *
 * Issue: operations.push() was generating:
 *   struct.operations ++ [{:add, ...}]  # Warning: result ignored
 *
 * Fix: Now generates:
 *   struct = %{struct | operations: struct.operations ++ [{:add, ...}]}
 */
class Main {
    public static function main() {
        var builder = new TestBuilder("test");
        builder.addItem("item1", 42);
        builder.addItem("item2", 100);
        builder.removeItem("item1");
        trace(builder.getItemCount());
    }
}

/**
 * Test class mimicking AlterTableBuilder pattern
 */
class TestBuilder {
    private var name: String;
    private var items: Array<BuilderItem>;

    public function new(name: String) {
        this.name = name;
        this.items = [];
    }

    /**
     * Method that pushes to array field
     * Should generate struct update, not bare concatenation
     */
    public function addItem(name: String, value: Int): TestBuilder {
        items.push(AddItem(name, value));
        return this;
    }

    /**
     * Another method that pushes to array field
     */
    public function removeItem(name: String): TestBuilder {
        items.push(RemoveItem(name));
        return this;
    }

    public function getItemCount(): Int {
        return items.length;
    }
}

enum BuilderItem {
    AddItem(name: String, value: Int);
    RemoveItem(name: String);
}