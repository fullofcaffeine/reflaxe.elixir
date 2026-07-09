defmodule StringKeyValueIteratorUnicode do
  def new(s_param) do
    struct = %{:__reflaxe_class__ => StringKeyValueIteratorUnicode, :offset => nil, :s => nil}
    struct = %{struct | offset: 0}
    struct = %{struct | s: s_param}
    struct
  end
  def has_next(struct) do
    StringTools.haxe_char_at(struct.s, struct.offset) != ""
  end
  def next(struct) do
    {struct, reflaxe_receiver_value_0} = {%{struct | offset: struct.offset + 1}, struct.offset}
    %{key: struct.offset, value: StringTools.fast_code_at(struct.s, reflaxe_receiver_value_0)}
  end
  def unicode_key_value_iterator(s_param) do
    StringKeyValueIteratorUnicode.new(s_param)
  end
end
