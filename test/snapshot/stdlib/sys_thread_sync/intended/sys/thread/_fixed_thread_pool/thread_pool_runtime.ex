defmodule ThreadPoolRuntime do
  def create_state() do
    (
            ref = make_ref()
            Process.put({:reflaxe_sys_thread_pool, ref}, %{shutdown: false})
            ref
        )
  end
  def is_shutdown(ref) do
    (
            case Process.get({:reflaxe_sys_thread_pool, ref}) do
              %{shutdown: shutdown} -> shutdown
              _ -> false
            end
        )
  end
  def mark_shutdown(ref) do
    Process.put({:reflaxe_sys_thread_pool, ref}, %{shutdown: true})
  end
end
