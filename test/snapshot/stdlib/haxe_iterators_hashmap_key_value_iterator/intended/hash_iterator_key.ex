defmodule HashIteratorKey do
  import Kernel, except: [to_string: 1], warn: false
  def new(id_param, code_param) do
    struct = %{:__reflaxe_class__ => HashIteratorKey, :id => nil, :code => nil}
    struct = %{struct | id: id_param}
    struct = %{struct | code: code_param}
    struct
  end
  def hash_code(struct) do
    struct.code
  end
  def to_string(struct) do
    "key:#{Reflaxe.Elixir.HaxeFloat.to_string(struct.id)}"
  end
end
