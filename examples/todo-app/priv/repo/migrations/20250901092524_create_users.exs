defmodule TodoApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  def up() do
    create table(:users) do
      add(:name, :string, [null: false])
      add(:email, :string, [null: false])
      add(:password_hash, :string, [null: false])
      add(:confirmed_at, :naive_datetime)
      add(:last_login_at, :naive_datetime)
      add(:active, :boolean, [default: true])
      timestamps()
    end
    create(unique_index(:users, [:email], [name: :users_email_unique]))
    create(index(:users, [:active]))
    create(index(:users, [:confirmed_at]))
    create(index(:users, [:last_login_at]))
    create(constraint(:users, :email_format, [check: "email ~ '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$'"]))
    create(constraint(:users, :name_length, [check: "length(name) >= 2"]))
  end
  def down() do
    drop(table(:users))
  end
end
