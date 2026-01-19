defmodule Parent do
  def new(name_param) do
    struct = %{:name => nil}
    struct = %{struct | name: name_param}
    struct
  end
  def get_name(struct) do
    struct.name
  end
  def get_description(struct) do
    "Parent: #{struct.name}"
  end
end
