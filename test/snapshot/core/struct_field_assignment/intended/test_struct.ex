defmodule TestStruct do
  def new() do
    struct = %{:field => nil}
    struct = %{struct | field: ""}
    struct
  end
  def write(struct, value) do
    (case typeof(value) do
      {:t_null} -> struct = %{struct | field: "#{struct.field}null"}
      {:t_int} -> struct = %{struct | field: "#{struct.field}#{inspect(value)}"}
      _ -> struct = %{struct | field: "#{struct.field}other"}
    end)
  end
end
