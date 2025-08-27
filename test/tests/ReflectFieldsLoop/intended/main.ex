defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    obj = %{"a" => 1, "b" => 2, "c" => 3}

    g_counter = 0
    g_array = Reflect.fields(obj)
    Enum.each(g_array, fn field -> 
      Log.trace("Field: " <> field, %{"fileName" => "Main.hx", "lineNumber" => 7, "className" => "Main", "methodName" => "main"})
    end)

    data = %{"errors" => %{"name" => ["Required"], "age" => ["Invalid"]}}

    changeset_errors = Reflect.field(data, "errors")

    if ((changeset_errors != nil)) do
      g_counter = 0
      g_array = Reflect.fields(changeset_errors)
      Enum.filter(g1, fn item -> Std.is_of_type(field_errors, Array) end)
    else
      nil
    end
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
