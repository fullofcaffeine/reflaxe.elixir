defmodule SemaphoreRuntime do
  def create(value) do
    if (value < 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.thread.Semaphore initial value must be >= 0"]
    end
    (
                ref = make_ref()
                pid = spawn(fn -> SemaphoreRuntime.server_loop(ref, value, :queue.new()) end)
                {ref, pid}
            )
  end
  def acquire(ref) do
    acquire_with_timeout(ref, :infinity, true)
  end
  def try_acquire(ref, timeout \\ nil) do
    should_queue = Reflaxe.Elixir.HaxeFloat.neq(timeout, nil) and Reflaxe.Elixir.HaxeFloat.gt(timeout, 0)
    timeout_ms = if (should_queue), do: seconds_to_timeout(timeout), else: 5000
    acquire_with_timeout(ref, timeout_ms, should_queue)
  end
  defp acquire_with_timeout(ref, timeout_ms, should_queue) do
    (
                {semaphore_ref, pid} = ref
                token = make_ref()
                send(pid, {:acquire, self(), token, should_queue})
                receive do
                  {:semaphore_acquire, ^semaphore_ref, ^token, ok} -> ok
                after
                  timeout_ms ->
                    send(pid, {:cancel, token})
                    false
                end
            )
  end
  def release(ref) do
    (
                {_semaphore_ref, pid} = ref
                send(pid, :release)
                :ok
            )
  end
  defp seconds_to_timeout(timeout) do
    if (Reflaxe.Elixir.HaxeFloat.eq(timeout, nil)) do
      0
    else
      if (Reflaxe.Elixir.HaxeFloat.lte(timeout, 0)) do
        0
      else
        Reflaxe.Elixir.HaxeFloat.ceil_int(Reflaxe.Elixir.HaxeFloat.mul(timeout, 1000))
      end
    end
  end
  def server_loop(ref, available, waiters) do

                receive do
                  {:acquire, caller, token, should_queue} ->
                    cond do
                      available > 0 ->
                        send(caller, {:semaphore_acquire, ref, token, true})
                        SemaphoreRuntime.server_loop(ref, available - 1, waiters)
                      should_queue ->
                        SemaphoreRuntime.server_loop(ref, available, :queue.in({caller, token}, waiters))
                      true ->
                        send(caller, {:semaphore_acquire, ref, token, false})
                        SemaphoreRuntime.server_loop(ref, available, waiters)
                    end

                  {:cancel, token} ->
                    filtered =
                      waiters
                      |> :queue.to_list()
                      |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                      |> Enum.reduce(:queue.new(), fn waiter, queue -> :queue.in(waiter, queue) end)
                    SemaphoreRuntime.server_loop(ref, available, filtered)

                  :release ->
                    case :queue.out(waiters) do
                      {{:value, {caller, token}}, rest} ->
                        send(caller, {:semaphore_acquire, ref, token, true})
                        SemaphoreRuntime.server_loop(ref, available, rest)
                      {:empty, _} ->
                        SemaphoreRuntime.server_loop(ref, available + 1, waiters)
                    end
                end

  end
end
