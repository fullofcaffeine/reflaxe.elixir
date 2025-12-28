defmodule TestStruct do
  def new() do
    struct = %{:field => nil}
    struct = %{struct | field: ""}
    struct
  end
  def write(struct, value) do
    (case typeof(value) do
      {:t_null} -> struct = %{struct | field: "#{(fn -> struct.field end).()}null"}
      {:t_int} -> struct = %{struct | field: "#{(fn -> struct.field end).()}#{(fn -> inspect(value) end).()}"}
      _ -> struct = %{struct | field: "#{(fn -> struct.field end).()}other"}
    end)
  end
end
