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
  defp create_table(_struct, _name) do
    nil
  end
  defp add_column(_struct, _table, _name, _type, _primary_key, _default_value) do
    nil
  end
  defp add_timestamps(_struct, _table) do
    nil
  end
  defp drop_table(_struct, _name) do
    nil
  end
  defp add_index(_struct, _table, _columns, _options) do
    nil
  end
  defp add_check_constraint(_struct, _table, _name, _condition) do
    nil
  end
end