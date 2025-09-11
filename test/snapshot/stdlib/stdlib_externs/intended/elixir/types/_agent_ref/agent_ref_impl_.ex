defmodule AgentRef_Impl_ do
  def from_pid(pid) do
    this1 = pid
    this1
  end
  def named(name) do
    ref = __elixir__.call(":" <> name)
    this1 = ref
    this1
  end
  def to_pid(this1) do
    this1
  end
  def is_alive(this1) do
    __elixir__.call("Process.alive?(" <> Std.string(this1) <> ")")
  end
  def to_value(this1) do
    this1
  end
  defp from_dynamic(d) do
    this1 = d
    this1
  end
  defp to_dynamic(this1) do
    this1
  end
  defp _new(ref) do
    this1 = ref
    this1
  end
end