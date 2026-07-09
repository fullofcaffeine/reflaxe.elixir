defmodule TestString do
  def new(s) do
    struct = %{:__reflaxe_class__ => TestString, :str => nil}
    struct = %{struct | str: s}
    struct
  end
  def cca(struct, index) do
    if (index < String.length(struct.str)) do
      StringTools.haxe_char_code_at(struct.str, index)
    else
      0
    end
  end
end
