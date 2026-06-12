defmodule Sys.Thread.Mutex do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.Mutex, :ref => nil}
    struct = %{struct | ref: MutexRuntime.create()}
    struct
  end
  def acquire(struct) do
    MutexRuntime.acquire(struct.ref)
  end
  def try_acquire(struct) do
    MutexRuntime.try_acquire(struct.ref)
  end
  def release(struct) do
    MutexRuntime.release(struct.ref)
  end
end
