defmodule ThreadRuntime do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, ThreadRuntime, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, ThreadRuntime, key}
    Process.put(static_key, {:set, value})
    value
  end
  def event_loop_key() do
    __haxe_static_get__(:event_loop_key, {:reflaxe_sys_thread_event_loop})
  end
  def event_loop_key(value) do
    __haxe_static_put__(:event_loop_key, value)
  end
  def thread_role_key() do
    __haxe_static_get__(:thread_role_key, {:reflaxe_sys_thread_role})
  end
  def thread_role_key(value) do
    __haxe_static_put__(:thread_role_key, value)
  end
  def self_pid() do
    self()
  end
  def spawn_process(job) do
    (
                role_key = ThreadRuntime.thread_role_key()
                spawn(fn ->
                  Process.put(role_key, :plain)
                  job.()
                end)
            )
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
  def install_event_loop() do
    created = Sys.Thread.EventLoop.new()
    Process.put(ThreadRuntime.event_loop_key(), created)
    created
  end
  def existing_event_loop() do
    Process.get(ThreadRuntime.event_loop_key())
  end
  def clear_event_loop() do
    Process.delete(ThreadRuntime.event_loop_key())
  end
  def is_plain_thread() do
    Process.get(ThreadRuntime.thread_role_key()) == :plain
  end
end
