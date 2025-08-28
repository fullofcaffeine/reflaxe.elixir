defmodule CreatePostsTable do
  use Ecto.Migration

  def up do
    create table(:posts) do
      add :title, :string
      add :content, :text
      add :view_count, :integer
      add :user_id, :references
      timestamps()
    end
  end

  def down do
    drop table(:posts)
  end

end