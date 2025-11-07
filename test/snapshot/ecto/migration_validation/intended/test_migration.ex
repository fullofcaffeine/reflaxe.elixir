defmodule TestMigration do
  def up(struct) do
    _ = struct.createTable("users").addColumn("id", {:integer}, %{:primary_key => true, :auto_generate => true}).addColumn("name", {:string}, %{:nullable => false}).addColumn("email", {:string}, %{:nullable => false}).addTimestamps().addIndex(["email"], %{:unique => true})
    _ = struct.createTable("posts").addColumn("id", {:integer}, %{:primary_key => true, :auto_generate => true}).addColumn("title", {:string}, %{:nullable => false}).addColumn("content", {:text}).addColumn("author_id", {:integer}).addTimestamps().addForeignKey("author_id", "userz")
  end
  def down(struct) do
    _ = struct.dropTable("posts")
    _ = struct.dropTable("users")
  end
end
