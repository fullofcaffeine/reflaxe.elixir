defmodule TestClass do
  def new(name_param) do
    struct = %{:name => nil}
    struct = %{struct | name: name_param}
    struct
  end
  def do_something(_) do
    nil
  end
end
