defmodule TestMigration2 do
  @compile {:nowarn_unused_function, [drop_table: 2, add_index: 3]}

  def up(struct) do
    struct.createTable("comments").addColumn("id", {:integer}, %{:primary_key => true, :auto_generate => true}).addColumn("content", {:text}).addColumn("post_id", {:integer}).addIndex(["contet"], %{:unique => false})
  end
  def down(struct) do
    struct.dropTable("comments")
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_index(struct, _table, _columns) do
    
  end
end
