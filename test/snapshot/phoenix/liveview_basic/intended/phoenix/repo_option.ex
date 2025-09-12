defmodule Phoenix.RepoOption do
  def timeout(arg0) do
    {0, arg0}
  end
  def log(arg0) do
    {1, arg0}
  end
  def telemetry(arg0) do
    {2, arg0}
  end
  def prefix(arg0) do
    {3, arg0}
  end
  def read_only(arg0) do
    {4, arg0}
  end
end