defmodule DequeRuntime do
  def create() do
    (
            ref = make_ref()
            pid = spawn(fn -> DequeRuntime.server_loop(ref, :queue.new(), :queue.new()) end)
            {ref, pid}
        )
  end
  def add(ref, value) do
    (
            {_deque_ref, pid} = ref
            send(pid, {:add, value})
            :ok
        )
  end
  def push(ref, value) do
    (
            {_deque_ref, pid} = ref
            send(pid, {:push, value})
            :ok
        )
  end
  def pop(ref, block) do
    (
            {deque_ref, pid} = ref
            token = make_ref()
            send(pid, {:pop, self(), token, block})
            receive do
              {:deque_pop, ^deque_ref, ^token, value} -> value
            end
        )
  end
  def server_loop(ref, queue, waiters) do
    
            receive do
              {:add, value} ->
                case :queue.out(waiters) do
                  {{:value, {caller, token}}, remaining_waiters} ->
                    send(caller, {:deque_pop, ref, token, value})
                    DequeRuntime.server_loop(ref, queue, remaining_waiters)
                  {:empty, _} ->
                    DequeRuntime.server_loop(ref, :queue.in(value, queue), waiters)
                end

              {:push, value} ->
                case :queue.out(waiters) do
                  {{:value, {caller, token}}, remaining_waiters} ->
                    send(caller, {:deque_pop, ref, token, value})
                    DequeRuntime.server_loop(ref, queue, remaining_waiters)
                  {:empty, _} ->
                    DequeRuntime.server_loop(ref, :queue.in_r(value, queue), waiters)
                end

              {:pop, caller, token, block} ->
                case :queue.out(queue) do
                  {{:value, value}, remaining_queue} ->
                    send(caller, {:deque_pop, ref, token, value})
                    DequeRuntime.server_loop(ref, remaining_queue, waiters)
                  {:empty, _} ->
                    if block do
                      DequeRuntime.server_loop(ref, queue, :queue.in({caller, token}, waiters))
                    else
                      send(caller, {:deque_pop, ref, token, nil})
                      DequeRuntime.server_loop(ref, queue, waiters)
                    end
                end
            end
        
  end
end
