defmodule CreateTodos do
  def up(struct) do
    struct.create_table("todos").add_column("title", {:String}, %{:nullable => false}).add_column("description", {:Text}).add_column("completed", {:Boolean}, %{:default_value => false}).add_column("priority", {:String}).add_column("due_date", {:DateTime}).add_column("tags", {:Json}).add_column("user_id", {:Integer}).add_timestamps().add_index(["user_id"]).add_index(["completed"])
  end
  def down(struct) do
    struct.drop_table("todos")
  end
end