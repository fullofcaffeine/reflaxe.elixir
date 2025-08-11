defmodule CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      add :is_active, :boolean, default: true
      
      timestamps()
    end
    
    create unique_index(:users, [:email])
    create index(:users, [:name])
  end
end