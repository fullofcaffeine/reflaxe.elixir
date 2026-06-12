defmodule Sys.Thread.Deque do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.Deque, :ref => nil}
    struct = %{struct | ref: DequeRuntime.create()}
    struct
  end
  def add(struct, i) do
    DequeRuntime.add(struct.ref, i)
  end
  def push(struct, i) do
    DequeRuntime.push(struct.ref, i)
  end
  def pop(struct, block) do
    DequeRuntime.pop(struct.ref, block)
  end
end
