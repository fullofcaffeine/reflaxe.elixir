defmodule ThreadRuntime do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, ThreadRuntime, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, ThreadRuntime, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def event_loop_key() do
    __haxe_static_get__(:event_loop_key, {:reflaxe_sys_thread_event_loop})
  end
  def event_loop_key(value) do
    __haxe_static_put__(:event_loop_key, value)
  end
  def self_pid() do
    self()
  end
  def spawn_process(job) do
    spawn(fn -> job.() end)
  end
  def send_message(pid, msg) do
    send(pid, {:reflaxe_sys_thread_message, msg})
  end
  def read_message(block) do
    if (block) do
      (
                      receive do
                        {:reflaxe_sys_thread_message, msg} -> msg
                      end
                  )
    else
      (
                  receive do
                    {:reflaxe_sys_thread_message, msg} -> msg
                  after
                    0 -> nil
                  end
              )
    end
  end
  def ensure_event_loop() do
    existing = Process.get(ThreadRuntime.event_loop_key())
    if (not Kernel.is_nil(existing)) do
      existing
    else
      created = Sys.Thread.EventLoop.new()
      Process.put(ThreadRuntime.event_loop_key(), created)
      created
    end
  end
  def current_event_loop() do
    ensure_event_loop()
  end
end
