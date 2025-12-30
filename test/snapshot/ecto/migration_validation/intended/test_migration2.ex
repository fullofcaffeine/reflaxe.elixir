defmodule TestMigration2 do
  def up(struct) do
    TableBuilder.add_index(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "comments", nil), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "content", {:text}, nil), "post_id", {:integer}, nil), ["content"], %{:unique => false})
  end
  def down(struct) do
    Migration.drop_table(struct, "comments", nil)
  end
end
