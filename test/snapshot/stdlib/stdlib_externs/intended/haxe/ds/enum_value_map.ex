defmodule EnumValueMap do
  def copy(struct) do
    copied = %{}
    copied = Map.put(copied, "root", struct.root)
    copied
  end
end
