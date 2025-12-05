defmodule EnumValueMap do
  def copy(_struct) do
    copied = %{}
    copied = Map.put(copied, "root", struct.root)
    copied
  end
end
