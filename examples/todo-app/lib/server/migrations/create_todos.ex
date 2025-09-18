defmodule CreateTodos do
  def up() do
    :nil.add_timestamps().add_index(["user_id"]).add_index(["completed"])
  end
  def down() do
    struct.drop_table("todos")
  end
end