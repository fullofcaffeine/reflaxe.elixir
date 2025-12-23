defmodule EctoMigrationsExample.Repo.Migrations.CreatePosts do
  use Ecto.Migration
  def up() do
    create table(:posts) do
      add(:title, :string, [null: false])
      add(:content, :text)
      add(:published, :boolean, [default: false])
      add(:view_count, :integer, [default: 0])
      add(:user_id, references(:users, [on_delete: :delete_all]))
      timestamps()
    end
    create(index(:posts, [:user_id]))
    create(index(:posts, [:published, :inserted_at]))
    create(constraint(:posts, :positive_view_count, [check: "view_count >= 0"]))
  end
  def down() do
    drop(table(:posts))
  end
end
