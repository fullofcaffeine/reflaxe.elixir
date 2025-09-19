defmodule TreeNode do
  def get_height(struct) do
    struct._height
  end
  def to_string(struct) do
    temp_string = nil
    if (struct.left == nil) do
      temp_string = ""
    else
      temp_string = struct.left.to_string() <> ", "
    end
    temp_string1 = nil
    if (struct.right == nil) do
      temp_string1 = ""
    else
      temp_string1 = ", " <> struct.right.to_string()
    end
    (temp_string) <> ("" <> Std.string(struct.key) <> " => " <> Std.string(struct.value)) <> (temp_string1)
  end
end