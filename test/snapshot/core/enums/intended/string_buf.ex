defmodule StringBuf do
  defp get_length(struct) do
    _joined = __instance_variable_not_available_in_this_context__.parts.join("")
    length(joined)
  end
  def add(struct, x) do
    _str = if.((x == nil), {:do, "null"}, {:else, to_string.(x)})
    __instance_variable_not_available_in_this_context__.parts.push(str)
  end
  def add_char(struct, c) do
    __instance_variable_not_available_in_this_context__.parts.push(__elixir__.("<<{0}::utf8>>", c))
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    _substr = cond do
  (len == nil) ->
    _len2 = nil
    if.((len2 == nil), {:do, __elixir__.("String.slice({0}, {1}..-1)", s, pos)}, {:else, __elixir__.("String.slice({0}, {1}, {2})", s, pos, len2)})
  (len == nil) -> __elixir__.("String.slice({0}, {1}..-1)", s, pos)
  :true -> __elixir__.("String.slice({0}, {1}, {2})", s, pos, len)
  :true -> :nil
end
    __instance_variable_not_available_in_this_context__.parts.push(substr)
  end
  def to_string(struct) do
    __elixir__.("IO.iodata_to_binary({0})", __instance_variable_not_available_in_this_context__.parts)
  end
end