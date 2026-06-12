defmodule Sys.Thread.Lock do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.Lock, :ref => nil}
    struct = %{struct | ref: LockRuntime.create()}
    struct
  end
  def wait(struct, timeout) do
    LockRuntime.wait(struct.ref, timeout)
  end
  def release(struct) do
    LockRuntime.release(struct.ref)
  end
end
