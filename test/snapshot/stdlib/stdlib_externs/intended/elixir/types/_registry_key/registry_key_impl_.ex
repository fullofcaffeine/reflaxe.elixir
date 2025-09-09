defmodule RegistryKey_Impl_ do
  def _new(key) do
    this1 = nil
    this1 = key
    this1
  end
  def from_string(str) do
    key = __elixir__.call("String.to_atom(" <> str <> ")")
    this1 = nil
    this1 = key
    this1
  end
  def from_int(i) do
    this1 = nil
    this1 = i
    this1
  end
  def from_tuple2(t) do
    this1 = nil
    this1 = t
    this1
  end
  def tuple(a, b) do
    this1 = nil
    this1 = {a, b}
    this1
  end
  def tuple3(a, b, c) do
    this1 = nil
    this1 = {a, b, c}
    this1
  end
  def via(module, name) do
    key = __elixir__.call("{:via, String.to_atom(" <> module <> "), " <> Std.string(name) <> "}")
    this1 = nil
    this1 = key
    this1
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
end