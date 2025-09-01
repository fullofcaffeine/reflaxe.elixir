defmodule StackItem do
  def c_function() do
    {:CFunction}
  end
  def module(arg0) do
    {:Module, arg0}
  end
  def file_pos(arg0, arg1, arg2, arg3) do
    {:FilePos, arg0, arg1, arg2, arg3}
  end
  def method(arg0, arg1) do
    {:Method, arg0, arg1}
  end
  def local_function(arg0) do
    {:LocalFunction, arg0}
  end
end