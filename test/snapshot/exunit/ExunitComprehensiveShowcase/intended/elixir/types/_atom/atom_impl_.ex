defmodule Atom_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(s) do
    s
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1 == other
  end
  def not_equals(this1, other) do
    this1 != other
  end
  def from_string(s) do
    s
  end
end
