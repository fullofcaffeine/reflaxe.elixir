defmodule Phoenix.MountResult do
  def ok(arg0) do
    {0, arg0}
  end
  def ok_with_temporary_assigns(arg0, arg1) do
    {1, arg0, arg1}
  end
  def error(arg0) do
    {2, arg0}
  end
end