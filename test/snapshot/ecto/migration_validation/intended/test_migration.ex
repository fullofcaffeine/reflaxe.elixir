defmodule TestMigration do
  def up(struct) do
    _ = TableBuilder.add_index(TableBuilder.add_timestamps(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "users"), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "name", {:string}, %{:nullable => false}), "email", {:string}, %{:nullable => false})), ["email"], %{:unique => true})
    _ = TableBuilder.add_foreign_key(TableBuilder.add_timestamps(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(TableBuilder.add_column(Migration.create_table(struct, "posts"), "id", {:integer}, %{:primary_key => true, :auto_generate => true}), "title", {:string}, %{:nullable => false}), "content", {:text}), "author_id", {:integer})), "author_id", "userz")
  end
  def down(struct) do
    _ = Migration.drop_table(struct, "posts")
    _ = Migration.drop_table(struct, "users")
  end
end
