defmodule RepoOption do
  def timeout(arg0) do
    {:Timeout, arg0}
  end
  def log(arg0) do
    {:Log, arg0}
  end
  def telemetry(arg0) do
    {:Telemetry, arg0}
  end
  def prefix(arg0) do
    {:Prefix, arg0}
  end
  def read_only(arg0) do
    {:ReadOnly, arg0}
  end
end