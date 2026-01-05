defmodule TaskRef_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(task) do
    task
  end
  def pid(this1) do
    task = this1
    task.pid
  end
  def ref(this1) do
    task = this1
    task.ref
  end
  def owner(this1) do
    task = this1
    task.owner
  end
  def is_alive(this1) do
    Process.alive?((fn ->
      task = this1
      task.pid
    end).())
  end
  def to_string(this1) do
    Kernel.inspect(this1)
  end
end
