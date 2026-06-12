defmodule Sys.Thread.Thread do
  defp new(pid_param) do
    struct = %{:__reflaxe_class__ => Sys.Thread.Thread, :pid => nil, :events => nil}
    struct = %{struct | pid: pid_param}
    struct
  end
  def get_events(_struct) do
    ThreadRuntime.current_event_loop()
  end
  def send_message(struct, msg) do
    ThreadRuntime.send_message(struct.pid, msg)
  end
  def current() do
    new(ThreadRuntime.self_pid())
  end
  def create(job) do
    new(ThreadRuntime.spawn_process(job))
  end
  def run_with_event_loop(job) do
    loop = ThreadRuntime.ensure_event_loop()
    _ = job.()
    _ = apply(Map.get(loop, :__reflaxe_class__) || Map.get(loop, :__struct__), :loop, [loop])
  end
  def create_with_event_loop(job) do
    create(fn -> run_with_event_loop(job) end)
  end
  def read_message(block) do
    ThreadRuntime.read_message(block)
  end
end
