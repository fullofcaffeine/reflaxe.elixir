defmodule Pid_Impl_ do
  def _new(pid) do
    this1 = pid
    this1
  end
  def from_string(str) do
    pid = __elixir__.call("Process.pid_from_string(" <> str <> ")")
    this1 = pid
    this1
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
  def is_self(this1) do
    __elixir__.call("" <> Std.string(this1) <> " == self()")
  end
  def is_alive(this1) do
    __elixir__.call("Process.alive?(" <> Std.string(this1) <> ")")
  end
  def node(this1) do
    __elixir__.call("node(" <> Std.string(this1) <> ")")
  end
end