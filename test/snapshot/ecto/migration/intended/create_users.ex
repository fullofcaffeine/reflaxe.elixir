defmodule CreateUsers do
  @compile {:nowarn_unused_function, [drop_table: 2]}

  def up(struct) do
    _ = struct.createTable("users")
    _ = struct.addColumn("users", "id", "serial", true, nil)
    _ = struct.addColumn("users", "name", "string", false, nil)
    _ = struct.addColumn("users", "email", "string", false, nil)
    _ = struct.addColumn("users", "age", "integer", nil, 0)
    _ = struct.addColumn("users", "bio", "text", nil, nil)
    _ = struct.addColumn("users", "active", "boolean", nil, true)
    _ = struct.addTimestamps("users")
    _ = struct.addIndex("users", ["email"], %{:unique => true})
    _ = struct.addIndex("users", ["name", "active"])
    _ = struct.addCheckConstraint("users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    struct.dropTable("users")
  end
  defp drop_table(struct, _name) do
    
  end
end
