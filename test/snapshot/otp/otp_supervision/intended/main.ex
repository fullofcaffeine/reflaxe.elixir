defmodule Main do
  def main() do
    test_supervisor()
    test_task()
    test_task_supervisor()
    test_supervision_tree()
  end

  defp test_supervisor() do
    children = [
      %{
        :id => "worker1",
        :start => {MyWorker, :start_link, [%{:name => "worker1"}]},
        :restart => :permanent,
        :type => :worker
      },
      %{
        :id => "worker2",
        :start => {MyWorker, :start_link, [%{:name => "worker2"}]},
        :restart => :temporary,
        :type => :worker
      },
      %{
        :id => "sub_supervisor",
        :start => {SubSupervisor, :start_link, [%{}]},
        :restart => :permanent,
        :type => :supervisor
      }
    ]

    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    {:ok, supervisor} = Supervisor.start_link(children, options)

    _children_list = Supervisor.which_children(supervisor)
    _counts = Supervisor.count_children(supervisor)

    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.terminate_child(supervisor, "worker2")
    Supervisor.delete_child(supervisor, "worker2")

    new_child = %{
      :id => "dynamic",
      :start => {DynamicWorker, :start_link, [%{}]},
      :restart => :transient,
      :type => :worker
    }
    Supervisor.start_child(supervisor, new_child)

    stats = Supervisor.count_children(supervisor)
    Log.trace("Active workers: #{stats.workers}, Supervisors: #{stats.supervisors}",
              %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "testSupervisor"})

    if Process.alive?(supervisor) do
      Log.trace("Supervisor is running",
                %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testSupervisor"})
    end

    Process.exit(supervisor, :normal)
  end

  defp test_task() do
    task = Task.async(fn ->
      Process.sleep(100)
      42
    end)

    result = Task.await(task)
    Log.trace("Async result: #{result}",
              %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testTask"})

    slow_task = Task.async(fn ->
      Process.sleep(5000)
      "slow"
    end)

    yield_result = Task.yield(slow_task, 100)
    if yield_result == nil do
      Log.trace("Task timed out",
                %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "testTask"})
      Task.shutdown(slow_task)
    end

    Task.start(fn ->
      Log.trace("Background task running",
                %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testTask"})
    end)

    Task.start_link(fn ->
      Log.trace("Linked task running",
                %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "testTask"})
    end)

    tasks = [
      Task.async(fn -> 1 end),
      Task.async(fn -> 2 end),
      Task.async(fn -> 3 end)
    ]

    results = Task.yield_many(tasks)

    # Process task results using Enum
    Enum.each(results, fn {_task, result} ->
      if result != nil do
        Log.trace("Task result: #{inspect(result)}",
                  %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testTask"})
      end
    end)

    quick_task = Task.async(fn -> "quick" end)
    _quick_result = Task.await(quick_task)

    # Create and await multiple tasks
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    tasks = Enum.map(funs, &Task.async/1)
    _concurrent_results = Enum.map(tasks, &Task.await/1)

    # Timed task with yield
    timed_task = Task.async(fn ->
      Process.sleep(50)
      "timed"
    end)

    timed_result = case Task.yield(timed_task, 100) do
      {:ok, value} -> value
      {:exit, _reason} -> nil
      nil ->
        Task.shutdown(timed_task)
        nil
    end

    Task.start(fn ->
      Log.trace("Fire and forget",
                %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "testTask"})
    end)

    _stream = Task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end

  defp test_task_supervisor() do
    case Task.Supervisor.start_link() do
      {:ok, supervisor} ->
        task = Task.Supervisor.async(supervisor, fn -> "supervised" end)
        result = Task.await(task)
        Log.trace("Supervised task result: #{result}",
                  %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "testTaskSupervisor"})

        nolink_task = Task.Supervisor.async_nolink(supervisor, fn -> "not linked" end)
        Task.await(nolink_task)

        Task.Supervisor.start_child(supervisor, fn ->
          Log.trace("Supervised child task",
                    %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "testTaskSupervisor"})
        end)

        children = Task.Supervisor.children(supervisor)
        Log.trace("Supervised tasks count: #{length(children)}",
                  %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "testTaskSupervisor"})

        _stream = Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)

        helper_task = Task.Supervisor.async(supervisor, fn -> "helper result" end)
        _supervised_result = Task.await(helper_task)

        # Create and await multiple supervised tasks
        funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
        tasks = Enum.map(funs, fn fun -> Task.Supervisor.async(supervisor, fun) end)
        _concurrent_results = Enum.map(tasks, &Task.await/1)

        Task.Supervisor.start_child(supervisor, fn ->
          Log.trace("Background supervised task",
                    %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "testTaskSupervisor"})
        end)

      _ ->
        Log.trace("Failed to start task supervisor",
                  %{:file_name => "Main.hx", :line_number => 230, :class_name => "Main", :method_name => "testTaskSupervisor"})
    end
  end

  defp test_supervision_tree() do
    children = [
      %{
        :id => "worker1",
        :start => {Worker1, :start_link, [%{}]},
        :restart => :permanent,
        :type => :worker
      },
      %{
        :id => "worker2",
        :start => {Worker2, :start_link, [%{}]},
        :restart => :temporary,
        :type => :worker
      },
      %{
        :id => "worker3",
        :start => {Worker3, :start_link, [%{}]},
        :restart => :transient,
        :type => :worker
      }
    ]

    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    {:ok, supervisor} = Supervisor.start_link(children, options)

    stats = Supervisor.count_children(supervisor)
    Log.trace("Supervisor - Workers: #{stats.workers}, Supervisors: #{stats.supervisors}",
              %{:file_name => "Main.hx", :line_number => 271, :class_name => "Main", :method_name => "testSupervisionTree"})

    children_list = Supervisor.which_children(supervisor)

    # Process children list using Enum
    Enum.each(children_list, fn {id, _pid, type, _modules} ->
      Log.trace("Child: #{inspect(id)}, Type: #{inspect(type)}",
                %{:file_name => "Main.hx", :line_number => 276, :class_name => "Main", :method_name => "testSupervisionTree"})
    end)

    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.stop(supervisor, :normal)
  end
end