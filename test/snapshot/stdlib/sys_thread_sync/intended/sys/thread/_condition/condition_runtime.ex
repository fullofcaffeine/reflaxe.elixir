defmodule ConditionRuntime do
  def create() do
    (
                ref = make_ref()
                pid = spawn(fn -> ConditionRuntime.server_loop(ref, nil, 0, :queue.new(), :queue.new()) end)
                {ref, pid}
            )
  end
  def acquire(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:acquire, self(), token})
                receive do
                  {:condition_acquire, ^condition_ref, ^token, :ok} -> :ok
                  {:condition_acquire, ^condition_ref, ^token, {:error, message}} -> raise message
                end
            )
  end
  def try_acquire(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:try_acquire, self(), token})
                receive do
                  {:condition_try_acquire, ^condition_ref, ^token, acquired} -> acquired
                end
            )
  end
  def release(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:release, self(), token})
                receive do
                  {:condition_release, ^condition_ref, ^token, :ok} -> :ok
                  {:condition_release, ^condition_ref, ^token, {:error, message}} -> raise message
                end
            )
  end
  def wait(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:wait, self(), token})
                receive do
                  {:condition_wait, ^condition_ref, ^token, :ok} -> :ok
                  {:condition_wait, ^condition_ref, ^token, {:error, message}} -> raise message
                end
            )
  end
  def signal(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:signal, self(), token})
                receive do
                  {:condition_signal, ^condition_ref, ^token, :ok} -> :ok
                end
            )
  end
  def broadcast(ref) do
    (
                {condition_ref, pid} = ref
                token = make_ref()
                send(pid, {:broadcast, self(), token})
                receive do
                  {:condition_broadcast, ^condition_ref, ^token, :ok} -> :ok
                end
            )
  end
  def server_loop(ref, owner, count, mutex_waiters, condition_waiters) do

                receive do
                  {:acquire, caller, token} ->
                    cond do
                      is_nil(owner) or owner == caller ->
                        send(caller, {:condition_acquire, ref, token, :ok})
                        ConditionRuntime.server_loop(ref, caller, count + 1, mutex_waiters, condition_waiters)
                      true ->
                        waiter = {caller, token, 1, :acquire}
                        ConditionRuntime.server_loop(ref, owner, count, :queue.in(waiter, mutex_waiters), condition_waiters)
                    end

                  {:try_acquire, caller, token} ->
                    cond do
                      is_nil(owner) or owner == caller ->
                        send(caller, {:condition_try_acquire, ref, token, true})
                        ConditionRuntime.server_loop(ref, caller, count + 1, mutex_waiters, condition_waiters)
                      true ->
                        send(caller, {:condition_try_acquire, ref, token, false})
                        ConditionRuntime.server_loop(ref, owner, count, mutex_waiters, condition_waiters)
                    end

                  {:release, caller, token} ->
                    cond do
                      owner != caller ->
                        send(caller, {:condition_release, ref, token, {:error, "sys.thread.Condition.release called by a process that does not own the mutex"}})
                        ConditionRuntime.server_loop(ref, owner, count, mutex_waiters, condition_waiters)
                      count > 1 ->
                        send(caller, {:condition_release, ref, token, :ok})
                        ConditionRuntime.server_loop(ref, owner, count - 1, mutex_waiters, condition_waiters)
                      true ->
                        send(caller, {:condition_release, ref, token, :ok})
                        ConditionRuntime.continue_or_grant(ref, nil, 0, mutex_waiters, condition_waiters)
                    end

                  {:wait, caller, token} ->
                    if owner != caller do
                      send(caller, {:condition_wait, ref, token, {:error, "sys.thread.Condition.wait called by a process that does not own the mutex"}})
                      ConditionRuntime.server_loop(ref, owner, count, mutex_waiters, condition_waiters)
                    else
                      waiter = {caller, token, count, :wait}
                      ConditionRuntime.continue_or_grant(ref, nil, 0, mutex_waiters, :queue.in(waiter, condition_waiters))
                    end

                  {:signal, caller, token} ->
                    send(caller, {:condition_signal, ref, token, :ok})
                    case :queue.out(condition_waiters) do
                      {{:value, waiter}, remaining_condition_waiters} ->
                        ConditionRuntime.continue_or_grant(
                          ref,
                          owner,
                          count,
                          :queue.in(waiter, mutex_waiters),
                          remaining_condition_waiters
                        )
                      {:empty, _} ->
                        ConditionRuntime.server_loop(ref, owner, count, mutex_waiters, condition_waiters)
                    end

                  {:broadcast, caller, token} ->
                    send(caller, {:condition_broadcast, ref, token, :ok})
                    ConditionRuntime.continue_or_grant(
                      ref,
                      owner,
                      count,
                      :queue.join(mutex_waiters, condition_waiters),
                      :queue.new()
                    )
                end

  end
  def continue_or_grant(ref, owner, count, mutex_waiters, condition_waiters) do

                if is_nil(owner) do
                  case :queue.out(mutex_waiters) do
                    {{:value, {next_caller, next_token, next_count, reply_kind}}, remaining_mutex_waiters} ->
                      case reply_kind do
                        :acquire -> send(next_caller, {:condition_acquire, ref, next_token, :ok})
                        :wait -> send(next_caller, {:condition_wait, ref, next_token, :ok})
                      end
                      ConditionRuntime.server_loop(ref, next_caller, next_count, remaining_mutex_waiters, condition_waiters)
                    {:empty, _} ->
                      ConditionRuntime.server_loop(ref, nil, 0, mutex_waiters, condition_waiters)
                  end
                else
                  ConditionRuntime.server_loop(ref, owner, count, mutex_waiters, condition_waiters)
                end

  end
end
