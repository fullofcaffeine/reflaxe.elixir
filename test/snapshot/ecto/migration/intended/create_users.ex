defmodule CreateUsers do
  def up(struct) do
    struct.createTable("users")
    struct.addColumn("users", "id", "serial", true, nil)
    struct.addColumn("users", "name", "string", false, nil)
    struct.addColumn("users", "email", "string", false, nil)
    struct.addColumn("users", "age", "integer", nil, 0)
    struct.addColumn("users", "bio", "text", nil, nil)
    struct.addColumn("users", "active", "boolean", nil, true)
    struct.addTimestamps("users")
    struct.addIndex("users", ["email"], %{:unique => true})
    struct.addIndex("users", ["name", "active"])
    struct.addCheckConstraint("users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    struct.dropTable("users")
  end
  defp create_table(struct, name) do
    nil
  end
  defp add_column(struct, table, name, type, primary_key, default_value) do
    nil
  end
  defp add_timestamps(struct, table) do
    nil
  end
  defp drop_table(struct, name) do
    nil
  end
  defp add_index(struct, table, columns, options) do
    nil
  end
  defp add_check_constraint(struct, table, name, condition) do
    nil
  end
end