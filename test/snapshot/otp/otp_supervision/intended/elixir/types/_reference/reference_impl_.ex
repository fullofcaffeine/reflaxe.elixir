defmodule Reference_Impl_ do
  def _new(ref) do
    this1 = ref
    this1
  end
  def make() do
    ref = make_ref()
    this1 = ref
    this1
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
  def is_valid(this1) do
    __elixir__.call("is_reference(" <> Std.string(this1) <> ")")
  end
end