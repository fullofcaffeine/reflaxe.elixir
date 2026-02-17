defmodule CreateUsersTable do
  def up(struct) do
    _ = create_table(struct, "users")
    _ = add_column(struct, "users", "name", "string")
    _ = add_column(struct, "users", "email", "string")
    _ = add_column(struct, "users", "age", "integer")
    _ = add_index(struct, "users", ["email"])
    _ = timestamps(struct)
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(_struct, _table_name) do
    
  end
  defp drop_table(_struct, _table_name) do
    
  end
  defp add_column(_struct, _table, _column, _type) do
    
  end
  defp add_index(_struct, _table, _columns) do
    
  end
  defp timestamps(_struct) do
    
  end
end
