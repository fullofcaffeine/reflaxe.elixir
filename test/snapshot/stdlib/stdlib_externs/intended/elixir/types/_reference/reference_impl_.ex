defmodule Reference_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(ref) do
    ref
  end
  def make() do
    ref = make_ref()
    ref
  end
  def to_string(this1) do
    elixir__.("inspect(#{Kernel.to_string(this1)})")
  end
  def is_valid(this1) do
    elixir__.("is_reference(#{Kernel.to_string(this1)})")
  end
end
