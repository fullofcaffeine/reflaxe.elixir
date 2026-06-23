defmodule PhoenixHxTodo.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration
  def up() do
    create table(:chat_messages) do
      add(:body, :text, [null: false])
      add(:user_id, :integer, [null: false])
      timestamps()
    end
    create(index(:chat_messages, [:user_id]))
  end
  def down() do
    drop(table(:chat_messages))
  end
end
