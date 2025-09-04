defmodule CreateUsersTable do
  def up(struct) do
    struct.createTable("users")
    struct.addColumn("users", "name", "string")
    struct.addColumn("users", "email", "string")
    struct.addColumn("users", "age", "integer")
    struct.addIndex("users", ["email"])
    struct.timestamps()
  end
  def down(struct) do
    struct.dropTable("users")
  end
  defp create_table(_struct, _table_name) do
    nil
  end
  defp drop_table(_struct, _table_name) do
    nil
  end
  defp add_column(_struct, _table, _column, _type) do
    nil
  end
  defp add_index(_struct, _table, _columns) do
    nil
  end
  defp timestamps(_struct) do
    nil
  end
end