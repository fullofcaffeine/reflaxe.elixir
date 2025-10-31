defmodule Phoenix.RepoOption do
  def timeout(arg0) do
    {:timeout, arg0}
  end
  def log(arg0) do
    {:log, arg0}
  end
  def telemetry(arg0) do
    {:telemetry, arg0}
  end
  def prefix(arg0) do
    {:prefix, arg0}
  end
  def read_only(arg0) do
    {:read_only, arg0}
  end
end
