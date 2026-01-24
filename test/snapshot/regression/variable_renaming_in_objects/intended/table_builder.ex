defmodule TableBuilder do
  def new() do
    struct = %{:__reflaxe_class__ => TableBuilder, :columns => nil}
    struct = %{struct | columns: []}
    struct
  end
  def add_column(struct, struct, name, type, options) do
    new_columns = struct.columns ++ [%{:name => name, :type => type, :options => options}]
    %{:columns => new_columns}
  end
end
