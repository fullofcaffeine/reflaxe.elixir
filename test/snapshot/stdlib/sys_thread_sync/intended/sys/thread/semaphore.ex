defmodule Sys.Thread.Semaphore do
  def new(value) do
    struct = %{:__reflaxe_class__ => Sys.Thread.Semaphore, :ref => nil}
    struct = %{struct | ref: SemaphoreRuntime.create(value)}
    struct
  end
  def acquire(struct) do
    SemaphoreRuntime.acquire(struct.ref)
  end
  def try_acquire(struct, timeout \\ nil) do
    SemaphoreRuntime.try_acquire(struct.ref, timeout)
  end
  def release(struct) do
    SemaphoreRuntime.release(struct.ref)
  end
end
