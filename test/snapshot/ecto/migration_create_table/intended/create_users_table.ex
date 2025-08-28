defmodule CreateUsersTable do
  use Ecto.Migration

  def up do
    create table(:users) do
      # columns will be added by subsequent DSL calls
    end
    add :name, :string
    add :email, :string
    add :age, :integer
    create index(:users, [:column_name])
    timestamps()
  end

  def down do
    drop table(:users)
  end

end