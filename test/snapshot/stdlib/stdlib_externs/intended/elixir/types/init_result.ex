defmodule elixir.types.InitResult do
  def ok(arg0) do
    {:Ok, arg0}
  end
  def ok_timeout(arg0, arg1) do
    {:OkTimeout, arg0, arg1}
  end
  def ok_hibernate(arg0) do
    {:OkHibernate, arg0}
  end
  def ok_continue(arg0, arg1) do
    {:OkContinue, arg0, arg1}
  end
  def stop(arg0) do
    {:Stop, arg0}
  end
  def ignore() do
    {:Ignore}
  end
end