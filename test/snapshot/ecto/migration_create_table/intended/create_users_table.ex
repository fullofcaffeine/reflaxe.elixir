defmodule CreateUsersTable do
  @compile {:nowarn_unused_function, [create_table: 2, drop_table: 2, add_column: 4, add_index: 3, timestamps: 1]}

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
  defp create_table(struct, _table_name) do
    
  end
  defp drop_table(struct, _table_name) do
    
  end
  defp add_column(struct, _table, _column, _type) do
    
  end
  defp add_index(struct, _table, _columns) do
    
  end
  defp timestamps(struct) do
    
  end
end
