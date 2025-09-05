defmodule Elixir.Types.MonitorInfo do
  def process_monitor(arg0) do
    {:ProcessMonitor, arg0}
  end
  def port_monitor(arg0) do
    {:PortMonitor, arg0}
  end
  def named_monitor(arg0) do
    {:NamedMonitor, arg0}
  end
end