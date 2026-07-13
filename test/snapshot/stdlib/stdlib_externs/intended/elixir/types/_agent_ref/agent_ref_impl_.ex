defmodule AgentRef_Impl_ do
  def from_pid(pid) do
    pid
  end
  def named(name) do
    name
  end
  def to_pid(this1) do
    this1
  end
  def is_alive(this1) do
    if (Kernel.is_pid(this1)) do
      Process.alive?(this1)
    else
      pid = Process.whereis(this1)
      Reflaxe.Elixir.HaxeFloat.neq(pid, nil) and Process.alive?(pid)
    end
  end
  def to_value(this1) do
    this1
  end
end
