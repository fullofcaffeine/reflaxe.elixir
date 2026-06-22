defmodule LockRuntime do
  def create() do
    (
                ref = make_ref()
                pid = spawn(fn -> LockRuntime.server_loop(ref, 0, :queue.new()) end)
                {ref, pid}
            )
  end
  def wait(ref, timeout) do
    should_queue = Reflaxe.Elixir.HaxeFloat.eq(timeout, nil) or Reflaxe.Elixir.HaxeFloat.gt(timeout, 0)
    timeout_ms = if (should_queue), do: seconds_to_timeout(timeout), else: 5000
    (
            {lock_ref, pid} = ref
            token = make_ref()
            send(pid, {:wait, self(), token, should_queue})
            receive do
              {:lock_wait, ^lock_ref, ^token, ok} -> ok
            after
              timeout_ms ->
                send(pid, {:cancel, token})
                false
            end
        )
  end
  def release(ref) do
    (
                {_lock_ref, pid} = ref
                send(pid, :release)
                :ok
            )
  end
  defp seconds_to_timeout(timeout) do
    if (Reflaxe.Elixir.HaxeFloat.eq(timeout, nil)) do
      :infinity
    else
      if (Reflaxe.Elixir.HaxeFloat.lte(timeout, 0)) do
        0
      else
        Reflaxe.Elixir.HaxeFloat.ceil_int(Reflaxe.Elixir.HaxeFloat.mul(timeout, 1000))
      end
    end
  end
  def server_loop(ref, permits, waiters) do

                receive do
                  {:wait, caller, token, should_queue} ->
                    cond do
                      permits > 0 ->
                        send(caller, {:lock_wait, ref, token, true})
                        LockRuntime.server_loop(ref, permits - 1, waiters)
                      should_queue ->
                        LockRuntime.server_loop(ref, permits, :queue.in({caller, token}, waiters))
                      true ->
                        send(caller, {:lock_wait, ref, token, false})
                        LockRuntime.server_loop(ref, permits, waiters)
                    end

                  {:cancel, token} ->
                    filtered =
                      waiters
                      |> :queue.to_list()
                      |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                      |> Enum.reduce(:queue.new(), fn waiter, queue -> :queue.in(waiter, queue) end)
                    LockRuntime.server_loop(ref, permits, filtered)

                  :release ->
                    case :queue.out(waiters) do
                      {{:value, {caller, token}}, rest} ->
                        send(caller, {:lock_wait, ref, token, true})
                        LockRuntime.server_loop(ref, permits, rest)
                      {:empty, _} ->
                        LockRuntime.server_loop(ref, permits + 1, waiters)
                    end
                end

  end
end
