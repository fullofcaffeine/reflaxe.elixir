import ecto.Migration;
import ecto.Migration.ColumnType;
import ecto.Migration.OnDeleteAction;
import ecto.Migration.OnUpdateAction;

/** Native composite references retain string column typing and scoped identity. */
@:migration({timestamp: "20240105120000"})
class CompositeReference extends Migration {
	public function up():Void {
		createTable("scoped_parents").addColumn("scope_id", ColumnType.Integer, {nullable: false})
			.addColumn("public_id", ColumnType.String(), {nullable: false})
			.addIndex(["scope_id", "public_id"], {unique: true});
		createTable("scoped_children").addColumn("scope-tag", ColumnType.Integer, {nullable: false}).addColumn("parent_key", ColumnType.String(), {
			nullable: false,
			reference: {
				table: "scoped_parents",
				column: "public_id",
				name: "scoped_parent_key",
				with: [{localColumn: "scope-tag", referencedColumn: "scope_id"}],
				onDelete: OnDeleteAction.Restrict,
				onUpdate: OnUpdateAction.Restrict
			}
		}).addColumn("future_key", ColumnType.String());
		alterTable("scoped_children").addColumn("backup_key", ColumnType.String(), {
			nullable: false,
			defaultValue: "shared",
			reference: {
				table: "scoped_parents",
				column: "public_id",
				with: [{localColumn: "scope-tag", referencedColumn: "scope_id"}]
			}
		}).modifyColumn("future_key", ColumnType.String(), {
			reference: {
				table: "scoped_parents",
				column: "public_id",
				with: [{localColumn: "scope-tag", referencedColumn: "scope_id"}]
			}
		});
	}

	public function down():Void {
		dropTable("scoped_children");
		dropTable("scoped_parents");
	}
}
