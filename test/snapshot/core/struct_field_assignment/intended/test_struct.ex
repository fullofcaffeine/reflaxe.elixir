defmodule TestStruct do
  @field nil
  def write(struct, value) do
    g = Type.typeof(value)
    case (g) do
      {:t_null} ->
        field = struct.field <> "null"
      {:t_int} ->
        field = struct.field <> Std.string(value)
      _ ->
        field = struct.field <> "other"
    end
  end
end