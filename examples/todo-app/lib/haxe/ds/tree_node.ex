defmodule TreeNode do
  def get_height() do
    struct._height
  end
  def to_string() do
    temp_string = nil
    if (self.left == nil) do
      temp_string = ""
    else
      temp_string = self.left.to_string() <> ", "
    end
    temp_string1 = nil
    if (self.right == nil) do
      temp_string1 = ""
    else
      temp_string1 = ", " <> self.right.to_string()
    end
    (tempString) <> ("" <> Std.string(self.key) <> " => " <> Std.string(self.value)) <> (tempString1)
  end
end