package;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240102120000"})
class AddUserBio extends Migration {
    public function up(): Void {
        alterTable("users")
            .addColumn("bio", ColumnType.Text);
    }

    public function down(): Void {
        alterTable("users")
            .removeColumn("bio");
    }
}

