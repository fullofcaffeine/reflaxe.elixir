defmodule MutexRuntime do
  def create() do
    (
            ref = make_ref()
            pid = spawn(fn -> MutexRuntime.server_loop(ref, nil, 0, :queue.new()) end)
            {ref, pid}
        )
  end
  def acquire(ref) do
    (
            {mutex_ref, pid} = ref
            token = make_ref()
            send(pid, {:acquire, self(), token})
            receive do
              {:mutex_acquire, ^mutex_ref, ^token, :ok} -> :ok
              {:mutex_acquire, ^mutex_ref, ^token, {:error, message}} -> raise message
            end
        )
  end
  def try_acquire(ref) do
    (
            {mutex_ref, pid} = ref
            token = make_ref()
            send(pid, {:try_acquire, self(), token})
            receive do
              {:mutex_try_acquire, ^mutex_ref, ^token, ok} -> ok
            end
        )
  end
  def release(ref) do
    (
            {mutex_ref, pid} = ref
            token = make_ref()
            send(pid, {:release, self(), token})
            receive do
              {:mutex_release, ^mutex_ref, ^token, :ok} -> :ok
              {:mutex_release, ^mutex_ref, ^token, {:error, message}} -> raise message
            end
        )
  end
  def server_loop(ref, owner, count, waiters) do
    
            receive do
              {:acquire, caller, token} ->
                cond do
                  is_nil(owner) or owner == caller ->
                    send(caller, {:mutex_acquire, ref, token, :ok})
                    MutexRuntime.server_loop(ref, caller, count + 1, waiters)
                  true ->
                    MutexRuntime.server_loop(ref, owner, count, :queue.in({caller, token}, waiters))
                end

              {:try_acquire, caller, token} ->
                cond do
                  is_nil(owner) or owner == caller ->
                    send(caller, {:mutex_try_acquire, ref, token, true})
                    MutexRuntime.server_loop(ref, caller, count + 1, waiters)
                  true ->
                    send(caller, {:mutex_try_acquire, ref, token, false})
                    MutexRuntime.server_loop(ref, owner, count, waiters)
                end

              {:release, caller, token} ->
                cond do
                  owner != caller ->
                    send(caller, {:mutex_release, ref, token, {:error, "sys.thread.Mutex.release called by a process that does not own the mutex"}})
                    MutexRuntime.server_loop(ref, owner, count, waiters)
                  count > 1 ->
                    send(caller, {:mutex_release, ref, token, :ok})
                    MutexRuntime.server_loop(ref, owner, count - 1, waiters)
                  true ->
                    send(caller, {:mutex_release, ref, token, :ok})
                    case :queue.out(waiters) do
                      {{:value, {next_caller, next_token}}, rest} ->
                        send(next_caller, {:mutex_acquire, ref, next_token, :ok})
                        MutexRuntime.server_loop(ref, next_caller, 1, rest)
                      {:empty, _} ->
                        MutexRuntime.server_loop(ref, nil, 0, waiters)
                    end
                end
            end
        
  end
end
