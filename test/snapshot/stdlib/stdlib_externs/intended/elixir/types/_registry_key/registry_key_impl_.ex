defmodule RegistryKey_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(key) do
    key
  end
  def from_string(str) do
    str
  end
  def from_int(i) do
    
  end
  def from_tuple2(t) do
    
  end
  def tuple(a, b) do
    _this1 = {a, b}
  end
  def tuple3(a, b, c) do
    _this1 = {a, b, c}
  end
  def via(module, name) do
    key = elixir__.("{:via, String.to_atom(#{module}), #{Kernel.to_string(name)}}")
    key
  end
  def to_string(this1) do
    Kernel.inspect(this1)
  end
end
