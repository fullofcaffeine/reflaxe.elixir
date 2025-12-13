defmodule CreateUsersTable do
  @compile {:nowarn_unused_function, [drop_table: 2]}

  def up(struct) do
    _ = struct.createTable("users")
    _ = struct.addColumn("users", "name", "string")
    _ = struct.addColumn("users", "email", "string")
    _ = struct.addColumn("users", "age", "integer")
    _ = struct.addIndex("users", ["email"])
    _ = struct.timestamps()
  end
  def down(struct) do
    struct.dropTable("users")
  end
  defp drop_table(struct, _name) do
    
  end
end
