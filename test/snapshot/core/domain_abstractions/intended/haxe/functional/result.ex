defmodule Haxe.Functional.Result do
  def ok(arg0) do
    {:Ok, arg0}
  end
  def error(arg0) do
    {:Error, arg0}
  end
end