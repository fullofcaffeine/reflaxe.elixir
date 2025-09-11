defmodule Haxe.StackItem do
  def c_function() do
    {0}
  end
  def module(arg0) do
    {1, arg0}
  end
  def file_pos(arg0, arg1, arg2, arg3) do
    {2, arg0, arg1, arg2, arg3}
  end
  def method(arg0, arg1) do
    {3, arg0, arg1}
  end
  def local_function(arg0) do
    {4, arg0}
  end
end