defmodule CreateUsersTable do
  def up(struct) do
    struct.create_table("users")
    struct.add_column("users", "name", "string")
    struct.add_column("users", "email", "string")
    struct.add_column("users", "age", "integer")
    struct.add_index("users", ["email"])
    struct.timestamps()
  end
  def down(struct) do
    struct.drop_table("users")
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