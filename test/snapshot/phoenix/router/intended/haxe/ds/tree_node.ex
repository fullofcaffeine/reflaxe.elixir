defmodule TreeNode do
  def get_height(struct) do
    struct._height
  end
  def to_string(struct) do
    (
"#{if struct.left == nil do
  ""
else
  "#{struct.left.toString()}, "
end}#{inspect(struct.key)} => #{inspect(struct.value)}#{if struct.right == nil do
  ""
else
  ", #{struct.right.toString()}"
end}"
)
  end
end
