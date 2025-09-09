defmodule ExitReason_Impl_ do
  def _new(reason) do
    this1 = nil
    this1 = reason
    this1
  end
  def normal() do
    reason = :normal
    this1 = nil
    this1 = reason
    this1
  end
  def kill() do
    reason = :kill
    this1 = nil
    this1 = reason
    this1
  end
  def shutdown() do
    reason = :shutdown
    this1 = nil
    this1 = reason
    this1
  end
  def shutdown_with(info) do
    reason = __elixir__.call("{:shutdown, " <> Std.string(info) <> "}")
    this1 = nil
    this1 = reason
    this1
  end
  def custom(reason) do
    this1 = nil
    this1 = reason
    this1
  end
  def to_string(this1) do
    __elixir__.call("inspect(" <> Std.string(this1) <> ")")
  end
end