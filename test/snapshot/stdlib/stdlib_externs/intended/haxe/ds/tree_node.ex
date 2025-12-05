defmodule TreeNode do
  def get_height(struct) do
    struct._height
  end
  def to_string(_struct) do
    "#{(fn -> if (struct.left == nil) do
  ""
else
  "#{(fn -> struct.left.toString() end).()}, "
end end).()}#{(fn -> inspect(struct.key) end).()} => #{(fn -> inspect(struct.value) end).()}#{(fn -> if (struct.right == nil) do
  ""
else
  ", #{(fn -> struct.right.toString() end).()}"
end end).()}"
  end
end
