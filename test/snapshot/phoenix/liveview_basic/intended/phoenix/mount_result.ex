defmodule Phoenix.MountResult do
  def ok(arg0) do
    {:ok, arg0}
  end
  def ok_with_temporary_assigns(arg0, arg1) do
    {:ok_with_temporary_assigns, arg0, arg1}
  end
  def error(arg0) do
    {:error, arg0}
  end
end
