package;

import ecto.Migration;
import ecto.Migration.ColumnType;
import ecto.Migration.OnDeleteAction;
import ecto.Migration.OnUpdateAction;

/** Reference actions belong to references/2, while null/default belong to add/3. */
@:migration({timestamp: "20240104120000"})
class ReferenceActions extends Migration {
	public function up():Void {
		createTable("children").addColumn("parent_id", References("parents"), {nullable: false, onDelete: Cascade, onUpdate: Cascade})
			.addColumn("optional_id", References("parents"), {onDelete: SetNull, onUpdate: SetNull})
			.addColumn("restricted_id", References("parents"), {onDelete: Restrict, onUpdate: Restrict})
			.addColumn("unchanged_id", References("parents"), {onDelete: NoAction, onUpdate: NoAction})
			.addColumn("default_id", References("parents"))
			.addColumn("counter", Integer, {nullable: false, defaultValue: 0});
		alterTable("children").addColumn("later_id", References("parents"), {onDelete: Cascade});
	}

	public function down():Void {
		dropConstraint("children", "children_parent_id_fkey");
		alterTable("children").modifyColumn("parent_id", References("parents"), {onDelete: Restrict, onUpdate: NoAction});
		dropTable("children");
	}
}
