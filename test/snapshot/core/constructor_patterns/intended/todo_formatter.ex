defmodule TodoFormatter do
  def new(format_param, prefix_param \\ "") do
    struct = %{:__reflaxe_class__ => TodoFormatter, :format => nil, :prefix => nil}
    struct = %{struct | format: format_param}
    struct = %{struct | prefix: prefix_param}
    struct
  end
  def format_todo(struct, todo) do
    struct.prefix <> " - " <> Reflaxe.Elixir.HaxeFloat.to_string(((case todo do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "title") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :title)
        end)
    end))) <> " (" <> struct.format <> ")"
  end
end
