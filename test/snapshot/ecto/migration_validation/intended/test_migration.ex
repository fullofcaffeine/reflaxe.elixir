defmodule TestMigration do
  def up(struct) do
    struct.create_table("users").add_column("id", {:integer}, %{:primary_key => true, :auto_generate => true}).add_column("name", {:string}, %{:nullable => false}).add_column("email", {:string}, %{:nullable => false}).add_timestamps().add_index(["email"], %{:unique => true})
    struct.create_table("posts").add_column("id", {:integer}, %{:primary_key => true, :auto_generate => true}).add_column("title", {:string}, %{:nullable => false}).add_column("content", {:text}).add_column("author_id", {:integer}).add_timestamps().add_foreign_key("author_id", "userz")
  end
  def down(struct) do
    struct.drop_table("posts")
    struct.drop_table("users")
  end
end