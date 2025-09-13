defmodule TodoFormatter do
  @format nil
  @prefix nil
  def format_todo(struct, todo) do
    struct.prefix <> " - " <> Std.string(todo.title) <> " (" <> struct.format <> ")"
  end
end