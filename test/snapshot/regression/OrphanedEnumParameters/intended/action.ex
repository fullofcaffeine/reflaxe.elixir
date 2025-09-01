defmodule Action do
  def move(arg0, arg1, arg2) do
    {:Move, arg0, arg1, arg2}
  end
  def rotate(arg0, arg1) do
    {:Rotate, arg0, arg1}
  end
  def scale(arg0) do
    {:Scale, arg0}
  end
end