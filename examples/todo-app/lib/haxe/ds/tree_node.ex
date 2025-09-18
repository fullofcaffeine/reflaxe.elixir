defmodule TreeNode do
  def get_height() do
    struct._height
  end
  def to_string() do
    temp_string = nil
    if (self.left == nil) do
      temp_string = ""
    else
      temp_string = :nil <> :nil
    end
    temp_string1 = nil
    if (self.right == nil) do
      temp_string1 = ""
    else
      temp_string1 = ", " <> :nil.to_string()
    end
    (tempString) <> (:nil <> :nil) <> (tempString1)
  end
end