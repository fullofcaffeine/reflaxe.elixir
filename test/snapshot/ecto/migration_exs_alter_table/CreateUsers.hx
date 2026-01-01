package;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240101120000"})
class CreateUsers extends Migration {
    public function up(): Void {
        createTable("users")
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addTimestamps();
    }

    public function down(): Void {
        dropTable("users");
    }
}

