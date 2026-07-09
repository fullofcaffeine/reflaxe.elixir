defmodule Sys.Thread.FixedThreadPool do
  def new(threads_count_param) do
    struct = %{:__reflaxe_class__ => Sys.Thread.FixedThreadPool, :threads_count => nil, :is_shutdown => nil, :queue => nil, :state_ref => nil}
    if (threads_count_param < 1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: ThreadPoolException.new("FixedThreadPool needs threadsCount to be at least 1.", nil, nil)]
    end
    struct = %{struct | threads_count: threads_count_param}
    struct = %{struct | queue: Sys.Thread.Deque.new()}
    struct = %{struct | state_ref: ThreadPoolRuntime.create_state()}
    worker_queue = struct.queue
    created = 0
    {_created} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {created}, fn _, {acc_created} ->
      try do
        if (acc_created < threads_count_param) do
          _ = Sys.Thread.Thread.create(fn -> worker_loop(worker_queue) end)
          acc_created = acc_created + 1
          {:cont, {acc_created}}
        else
          {:halt, {acc_created}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_created}}
        :throw, :continue ->
          {:cont, {acc_created}}
      end
    end)
    struct
  end
  def get_threads_count(struct) do
    struct.threads_count
  end
  def get_is_shutdown(struct) do
    ThreadPoolRuntime.is_shutdown(struct.state_ref)
  end
  def run(struct, task) do
    if (ThreadPoolRuntime.is_shutdown(struct.state_ref)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: ThreadPoolException.new("Task is rejected. Thread pool is shut down.", nil, nil)]
    end
    if (Reflaxe.Elixir.HaxeFloat.eq(task, nil)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: ThreadPoolException.new("Task to run must not be null.", nil, nil)]
    end
    reflaxe_dispatch_receiver = struct.queue
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add, [reflaxe_dispatch_receiver, task])
  end
  def shutdown(struct) do
    if (ThreadPoolRuntime.is_shutdown(struct.state_ref)) do
      nil
    else
      _ = ThreadPoolRuntime.mark_shutdown(struct.state_ref)
      _g = 0
      g_value = get_threads_count(struct)
      _ =
        Enum.each(0..(g_value - 1)//1, fn _ ->
          reflaxe_dispatch_receiver = struct.queue
          _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add, [reflaxe_dispatch_receiver, &shutdown_task/0])
        end)
    end
  end
  defp shutdown_task() do

  end
  defp worker_loop(worker_queue) do
    {_worker_queue} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {worker_queue}, fn _, {acc_worker_queue} ->
      try do
        task = apply(Map.get(acc_worker_queue, :__reflaxe_class__) || Map.get(acc_worker_queue, :__struct__), :pop, [acc_worker_queue, true])
        if (Reflaxe.Elixir.HaxeFloat.eq(task, &shutdown_task/0)) do
          throw({:break, {acc_worker_queue}})
        end
        _ = task.()
        {:cont, {acc_worker_queue}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_worker_queue}}
        :throw, :continue ->
          {:cont, {acc_worker_queue}}
      end
    end)
  end
end
