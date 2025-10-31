defmodule TestMigration do
  @compile {:nowarn_unused_function, [drop_table: 2, add_index: 3, add_foreign_key: 3]}

  def up(struct) do
    struct.createTable("users").addColumn("id", {:integer}, %{:primary_key => true, :auto_generate => true}).addColumn("name", {:string}, %{:nullable => false}).addColumn("email", {:string}, %{:nullable => false}).addTimestamps().addIndex(["email"], %{:unique => true})
    struct.createTable("posts").addColumn("id", {:integer}, %{:primary_key => true, :auto_generate => true}).addColumn("title", {:string}, %{:nullable => false}).addColumn("content", {:text}).addColumn("author_id", {:integer}).addTimestamps().addForeignKey("author_id", "userz")
  end
  def down(struct) do
    struct.dropTable("posts")
    struct.dropTable("users")
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_index(struct, _table, _columns) do
    
  end
  defp add_foreign_key(struct, _arg, _arg) do
    
  end
end
