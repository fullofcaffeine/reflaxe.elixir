defmodule Pid_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(pid) do
    pid
  end
  def from_string(str) do
    pid = elixir__.("Process.pid_from_string(#{str})")
    pid
  end
  def to_string(this1) do
    elixir__.("inspect(#{Kernel.to_string(this1)})")
  end
  def is_self(this1) do
    elixir__.("#{Kernel.to_string(this1)} == self()")
  end
  def is_alive(this1) do
    elixir__.("Process.alive?(#{Kernel.to_string(this1)})")
  end
  def node(this1) do
    elixir__.("node(#{Kernel.to_string(this1)})")
  end
end
