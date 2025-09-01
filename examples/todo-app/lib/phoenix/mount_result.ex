defmodule Phoenix.MountResult do
  def ok(arg0) do
    {:Ok, arg0}
  end
  def ok_with_temporary_assigns(arg0, arg1) do
    {:OkWithTemporaryAssigns, arg0, arg1}
  end
  def error(arg0) do
    {:Error, arg0}
  end
end