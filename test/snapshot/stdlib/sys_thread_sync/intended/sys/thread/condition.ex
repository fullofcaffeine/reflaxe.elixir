defmodule Sys.Thread.Condition do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.Condition, :ref => nil}
    struct = %{struct | ref: ConditionRuntime.create()}
    struct
  end
  def acquire(struct) do
    ConditionRuntime.acquire(struct.ref)
  end
  def try_acquire(struct) do
    ConditionRuntime.try_acquire(struct.ref)
  end
  def release(struct) do
    ConditionRuntime.release(struct.ref)
  end
  def wait(struct) do
    ConditionRuntime.wait(struct.ref)
  end
  def signal(struct) do
    ConditionRuntime.signal(struct.ref)
  end
  def broadcast(struct) do
    ConditionRuntime.broadcast(struct.ref)
  end
end
