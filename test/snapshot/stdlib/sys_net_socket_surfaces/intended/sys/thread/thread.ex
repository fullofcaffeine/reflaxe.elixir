defmodule Sys.Thread.Thread do
  defp new(pid_param) do
    struct = %{:__reflaxe_class__ => Sys.Thread.Thread, :pid => nil, :events => nil}
    struct = %{struct | pid: pid_param}
    struct
  end
  def get_events(_struct) do
    loop = ThreadRuntime.existing_event_loop()
    if (not Kernel.is_nil(loop)) do
      loop
    else
      if (ThreadRuntime.is_plain_thread()) do
        raise Reflaxe.Elixir.HaxeThrow, [value: NoEventLoopException.new("Event loop is not available. Refer to sys.thread.Thread.runWithEventLoop.", nil)]
      end
      ThreadRuntime.install_event_loop()
    end
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
    existing = ThreadRuntime.existing_event_loop()
    if (not Kernel.is_nil(existing)) do
      job.()
      nil
    else
      loop = ThreadRuntime.install_event_loop()
      try do
        job.()
        apply(Map.get(loop, :__reflaxe_class__) || Map.get(loop, :__struct__), :loop, [loop])
      rescue
        haxe_exception ->
          Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
          (case {(case haxe_exception do
            %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
            _ -> haxe_exception
          end), haxe_exception} do
            {error, _} when is_struct(error, Reflaxe.Exception) or is_map(error) and is_map_key(error, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, error) == Reflaxe.Exception ->
              ThreadRuntime.clear_event_loop()
              raise Reflaxe.Elixir.HaxeThrow, [value: error]
            _ ->
              reraise(haxe_exception, __STACKTRACE__)
          end)
      end
      ThreadRuntime.clear_event_loop()
    end
  end
  def create_with_event_loop(job) do
    create(fn -> run_with_event_loop(job) end)
  end
  def read_message(block) do
    ThreadRuntime.read_message(block)
  end
end
