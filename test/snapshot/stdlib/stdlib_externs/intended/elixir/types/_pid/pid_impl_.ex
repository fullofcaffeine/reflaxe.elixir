defmodule Pid_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(pid) do
    pid
  end
  def from_string(str) do
    pid = :erlang.list_to_pid(String.to_charlist(String.replace_prefix(str, "#PID", "")))
    pid
  end
  def to_string(this1) do
    inspect(this1)
  end
  def is_self(this1) do
    this1 == self()
  end
  def is_alive(this1) do
    Process.alive?(this1)
  end
  def node(this1) do
    node(this1)
  end
end
