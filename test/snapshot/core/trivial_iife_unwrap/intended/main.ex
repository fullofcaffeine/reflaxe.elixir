defmodule Main do
  def package_json(package_root) do
    Path.join(package_root.absolute, "package.json")
  end
  def preserve_binding_scope(value) do
    identity(
      (fn ->
         decorated = value <> "!"
         IO.puts(decorated)
         decorated
       end).()
    )
  end
  def preserve_remote_call_scope(value) do
    IO.puts(
      (fn ->
         decorated = value <> "?"
         IO.puts(decorated)
         decorated
       end).()
    )
  end
  def preserve_function_variable_scope(value) do
    callback = &identity/1
    callback.(
      (fn ->
         decorated = value <> "."
         IO.puts(decorated)
         decorated
       end).()
    )
  end
  def preserve_repeated_tuple_value(value) do
    identity_pair(
      (fn ->
         value = observe(value)
         {value, value}
       end).()
    )
  end
  def preserve_tuple_argument_order(first, second) do
    identity_pair(
      (fn ->
         first = observe(first)
         second = observe(second)
         {second, first}
       end).()
    )
  end
  defp observe(value) do
    IO.puts(value)
    value
  end
  defp identity_pair(value) do
    value
  end
  defp identity(value) do
    value
  end
end
