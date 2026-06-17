defmodule StringIteratorUnicode do
  def new(s_param) do
    struct = %{:__reflaxe_class__ => StringIteratorUnicode, :offset => nil, :s => nil}
    struct = %{struct | offset: 0}
    struct = %{struct | s: s_param}
    struct
  end
  def has_next(struct) do
    (if (struct.offset < 0) do
  ""
else
  String.at(struct.s, struct.offset) || ""
end) != ""
  end
  def next(struct) do
    struct = %{struct | s: struct.s}
    old_struct_offset = struct.offset
    struct = %{struct | offset: struct.offset + 1}
    index = old_struct_offset
    if (index < 0) do
      nil
    else
      Enum.at(String.to_charlist(struct.s), index)
    end
  end
  def unicode_iterator(s_param) do
    StringIteratorUnicode.new(s_param)
  end
end
