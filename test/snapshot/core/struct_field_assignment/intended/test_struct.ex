defmodule TestStruct do
  def new() do
    %{:field => ""}
  end
  def write(struct, value) do
    g = {:Typeof, value}
    case (g.elem(0)) do
      0 ->
        field = struct.field <> "null"
      1 ->
        field = struct.field <> Std.string(value)
      _ ->
        field = struct.field <> "other"
    end
  end
end