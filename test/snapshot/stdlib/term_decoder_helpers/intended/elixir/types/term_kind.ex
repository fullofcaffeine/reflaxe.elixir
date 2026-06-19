defmodule Elixir.Types.TermKind do
  def atom() do
    {0}
  end
  def binary() do
    {1}
  end
  def bitstring() do
    {2}
  end
  def boolean() do
    {3}
  end
  def float() do
    {4}
  end
  def function() do
    {5}
  end
  def integer() do
    {6}
  end
  def list() do
    {7}
  end
  def map() do
    {8}
  end
  def nil_fn() do
    {9}
  end
  def number() do
    {10}
  end
  def pid() do
    {11}
  end
  def port() do
    {12}
  end
  def reference() do
    {13}
  end
  def tuple() do
    {14}
  end
  def unknown() do
    {15}
  end
end
