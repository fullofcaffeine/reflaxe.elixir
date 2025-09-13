defmodule TestMigration2 do
  def up(struct) do
    struct.create_table("comments").add_column("id", {:integer}, %{:primary_key => true, :auto_generate => true}).add_column("content", {:text}).add_column("post_id", {:integer}).add_index(["contet"], %{:unique => false})
  end
  def down(struct) do
    struct.drop_table("comments")
  end
end