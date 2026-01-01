defmodule TodoApp.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration
  def up() do
    create table(:organizations) do
      add(:slug, :string, [null: false])
      add(:name, :string, [null: false])
      timestamps()
    end
    create(unique_index(:organizations, [:slug], [name: :organizations_slug_unique]))
  end
  def down() do
    drop(table(:organizations))
  end
end
