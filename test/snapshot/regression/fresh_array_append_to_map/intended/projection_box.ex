defmodule ProjectionBox do
  def new(offset_param) do
    struct = %{:__reflaxe_class__ => ProjectionBox, :offset => nil}
    struct = %{struct | offset: offset_param}
    struct
  end
  def project(struct, value) do
    struct = %{struct | offset: struct.offset + 1}
    value + struct.offset
  end
end
