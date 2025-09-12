defmodule Atom_Impl_ do
  # Static inline constants are not compiled as module attributes
  # They are inlined at compile time in Haxe
  def _new(s) do
    this1 = s
    this1
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
    this1 = s
    this1
  end
end