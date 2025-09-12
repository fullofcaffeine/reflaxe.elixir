defmodule TaskRef_Impl_ do
  def _new(task) do
    this1 = task
    this1
  end
  def pid(this1) do
    __elixir__.call("" <> Std.string(this1) <> ".pid")
  end
  def ref(this1) do
    __elixir__.call("" <> Std.string(this1) <> ".ref")
  end
  def owner(this1) do
    __elixir__.call("" <> Std.string(this1) <> ".owner")
  end
  def is_alive(this1) do
    __elixir__.call("Process.alive?(" <> Std.string(this1) <> ".pid)")
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
end