defmodule TestStruct do
  @field nil
  def write(struct, value) do
    g = Type.typeof(value)
    case (elem(g, 0)) do
      0 ->
        field = struct.field <> "null"
      1 ->
        field = struct.field <> Std.string(value)
      _ ->
        field = struct.field <> "other"
    end
  end
end