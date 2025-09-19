defmodule CreateTodos do
  def up() do
    struct.create_table("todos").add_column("title", {:string}, %{:nullable => false}).add_column("description", {:text}).add_column("completed", {:boolean}, %{:default_value => false}).add_column("priority", {:string}).add_column("due_date", {:date_time}).add_column("tags", {:json}).add_column("user_id", {:integer}).add_timestamps().add_index(["user_id"]).add_index(["completed"])
  end
  def down() do
    struct.drop_table("todos")
  end
end