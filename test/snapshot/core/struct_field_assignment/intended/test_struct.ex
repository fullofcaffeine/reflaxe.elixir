defmodule TestStruct do
  def write(struct, value) do
    (case typeof(value) do
      {:t_null} -> field = "#{(fn -> struct.field end).()}null"
      {:t_int} -> field = "#{(fn -> struct.field end).()}#{(fn -> inspect(value) end).()}"
      _ -> field = "#{(fn -> struct.field end).()}other"
    end)
  end
end
