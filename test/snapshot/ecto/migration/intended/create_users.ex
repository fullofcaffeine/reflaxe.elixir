defmodule CreateUsers do
  def up(struct) do
    struct.create_table("users")
    struct.add_column("users", "id", "serial", true, nil)
    struct.add_column("users", "name", "string", false, nil)
    struct.add_column("users", "email", "string", false, nil)
    struct.add_column("users", "age", "integer", nil, 0)
    struct.add_column("users", "bio", "text", nil, nil)
    struct.add_column("users", "active", "boolean", nil, true)
    struct.add_timestamps("users")
    struct.add_index("users", ["email"], %{:unique => true})
    struct.add_index("users", ["name", "active"])
    struct.add_check_constraint("users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    struct.drop_table("users")
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