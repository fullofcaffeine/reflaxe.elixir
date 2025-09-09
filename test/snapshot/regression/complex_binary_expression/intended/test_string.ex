defmodule TestString do
  @str nil
  def cca(struct, index) do
    if (index < length(struct.str)), do: struct.str.char_code_at(index), else: 0
  end
end