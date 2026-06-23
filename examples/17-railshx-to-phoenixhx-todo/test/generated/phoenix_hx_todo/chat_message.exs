defmodule PhoenixHxTodo.ChatMessage do
  use Ecto.Schema
  schema "chat_messages" do
    _ = field(:body, :string)
    _ = field(:user_id, :integer)
    _ = timestamps()
  end
  def new() do
    %{:__reflaxe_class__ => PhoenixHxTodo.ChatMessage, :id => nil, :body => nil, :user_id => nil}
  end

  def changeset(chatmessage, attrs) do
    chatmessage
    |> Ecto.Changeset.cast(attrs, [:body, :user_id])
    |> Ecto.Changeset.validate_required([:body, :user_id])
  end
end
