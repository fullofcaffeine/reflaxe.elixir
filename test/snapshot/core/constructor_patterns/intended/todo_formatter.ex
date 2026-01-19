defmodule TodoFormatter do
  def new(format_param, prefix_param) do
    struct = %{:format => nil, :prefix => nil}
    struct = %{struct | format: format_param}
    struct = %{struct | prefix: prefix_param}
    struct
  end
  def format_todo(struct, todo) do
    "#{struct.prefix} - #{todo.title} (#{struct.format})"
  end
end
