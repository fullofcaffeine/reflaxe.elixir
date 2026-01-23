defmodule TodoFormatter do
  def new(format_param, prefix_param) do
    struct = %{:format => nil, :prefix => nil}
    struct = %{struct | format: format_param}
    struct = %{struct | prefix: prefix_param}
    struct
  end
  def format_todo(struct, todo) do
    "#{struct.prefix} - #{(fn -> inspect(((case todo do
    _dyn_obj ->
      (case Map.fetch(_dyn_obj, "title") do
        {:ok, _dyn_value} -> _dyn_value
        _ ->
          Map.get(_dyn_obj, :title)
      end)
  end))) end).()} (#{struct.format})"
  end
end
