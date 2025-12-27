defmodule TestMigration2 do
  @compile {:nowarn_unused_function, [create_table: 3, drop_table: 3, add_column: 5, add_index: 4]}

  def up(struct) do
    TableBuilder.add_index(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "comments"), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "content", {:text}), "post_id", {:integer}), ["contet"], %{:unique => false})
  end
  def down(struct) do
    Migration.drop_table(struct, "comments")
  end
  defp create_table(struct, _name) do
    
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_column(struct, _arg, _arg, _arg, _arg) do
    
  end
  defp add_index(struct, _table, _columns, _options) do
    
  end
end
