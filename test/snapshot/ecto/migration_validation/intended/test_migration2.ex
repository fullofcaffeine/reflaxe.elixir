defmodule TestMigration2 do
  def up(struct) do
    struct.createTable("comments").addColumn("id", :integer, %{:primary_key => true, :auto_generate => true}).addColumn("content", :text).addColumn("post_id", :integer).addIndex(["contet"], %{:unique => false})
  end
  def down(struct) do
    struct.dropTable("comments")
  end
end
