defmodule TestMigration do
  def up(struct) do
    _ = TableBuilder.add_index(TableBuilder.add_timestamps(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "users", nil), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "name", {:string}, %{:nullable => false}), "email", {:string}, %{:nullable => false})), ["email"], %{:unique => true})
    _ = TableBuilder.add_foreign_key(TableBuilder.add_timestamps(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "posts", nil), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "title", {:string}, %{:nullable => false}), "content", {:text}, nil), "author_id", {:integer}, nil)), "author_id", "users", nil)
  end
  def down(struct) do
    _ = Migration.drop_table(struct, "posts", nil)
    _ = Migration.drop_table(struct, "users", nil)
  end
end
