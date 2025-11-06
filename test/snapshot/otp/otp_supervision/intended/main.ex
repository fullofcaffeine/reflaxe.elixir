defmodule Main do
  defp test_supervisor() do
    _ = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => {:permanent}, :type => {:supervisor}}]
    _ = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    _ = Supervisor.start_link(children, options)
    _ = Supervisor.which_children(result)
    _ = Supervisor.count_children(result)
    _ = Supervisor.restart_child(result, "worker1")
    _ = Supervisor.terminate_child(result, "worker2")
    _ = Supervisor.delete_child(result, "worker2")
    _ = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}
    _ = Supervisor.start_child(result, new_child)
    _ = Supervisor.count_children(result)
    _ = Log.trace("Active workers: #{(fn -> stats.workers end).()}, Supervisors: #{(fn -> stats.supervisors end).()}", %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "testSupervisor"})
    if (Process.process.alive?(result)) do
      Log.trace("Supervisor is running", %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testSupervisor"})
    end
    _ = Process.process.exit(result, "normal")
    _
  end
  defp test_task() do
    _ = Task.task.async((fn -> fn ->
      Process.process.sleep(100)
      42
    end end).())
    _ = Task.task.await(task)
    _ = Log.trace("Async result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testTask"})
    _ = Task.task.async((fn -> fn ->
      Process.process.sleep(5000)
      "slow"
    end end).())
    _ = Task.task.yield(slow_task, 100)
    if (Kernel.is_nil(yield_result)) do
      _ = Log.trace("Task timed out", %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "testTask"})
      _ = Task.task.shutdown(slow_task)
    end
    _ = Task.task.start(fn -> Log.trace("Background task running", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testTask"}) end)
    _ = Task.task.start_link(fn -> Log.trace("Linked task running", %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "testTask"}) end)
    _ = [Task.task.async(fn ->  end), Task.task.async(fn -> 2 end), Task.task.async(fn -> 3 end)]
    _ = Task.task.yield_many(tasks)
    _ = Enum.each(results, (fn -> fn item ->
    if (item.result != nil) do
    Log.trace("Task result: " <> inspect(item.result), %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testTask"})
  end
end end).())
    _ = Task.task.async(fn -> "quick" end)
    _ = Task.task.await(task2)
    _ = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    _ = Enum.each(funs, (fn -> fn item ->
    [].push(Task.task.async(item))
end end).())
    []
    _ = Enum.each(tasks2, (fn -> fn item ->
    [].push(Task.task.await(item))
end end).())
    []
    _ = Task.task.async((fn -> fn ->
      Process.process.sleep(50)
      "timed"
    end end).())
    result2 = Task.task.yield(task2, 100)
    if (Kernel.is_nil(result2)) do
      _ = Task.task.shutdown(task2)
      nil
    else
      (case result2 do
        0 ->
          value = elem(result2, 1)
          value
        1 -> nil
      end)
    end
    _ = Task.task.start(fn -> Log.trace("Fire and forget", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "testTask"}) end)
    _ = Task.task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    _ = Supervisor.task.supervisor.start_link()
    if (supervisor_result._0 == "ok") do
      supervisor = supervisor_result._1
      _ = Supervisor.task.supervisor.async(supervisor, fn -> "supervised" end)
      _ = Task.task.await(task)
      _ = Log.trace("Supervised task result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "testTaskSupervisor"})
      _ = Supervisor.task.supervisor.async_nolink(supervisor, fn -> "not linked" end)
      _ = Task.task.await(nolink_task)
      _ = Supervisor.task.supervisor.start_child(supervisor, fn -> Log.trace("Supervised child task", %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "testTaskSupervisor"}) end)
      _ = Supervisor.task.supervisor.children(supervisor)
      _ = Log.trace("Supervised tasks count: #{(fn -> length(children) end).()}", %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "testTaskSupervisor"})
      _ = Supervisor.task.supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      _ = Supervisor.task.supervisor.async(supervisor, fn -> "helper result" end)
      _ = Task.task.await(task2)
      _ = supervisor
      _ = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      _ = 0
      _ = Enum.map(funs, (fn -> fn item ->
  fun = funs[_g1]
  _g1 + 1
  _g = Enum.concat(_g, [Supervisor.task.supervisor.async(supervisor2, fun)])
end end).())
      []
      _ = 0
      _ = Enum.map(tasks, (fn -> fn item ->
  task2 = tasks[_g1]
  _g1 + 1
  _g = Enum.concat(_g, [Task.task.await(task2)])
end end).())
      []
      _ = Supervisor.task.supervisor.start_child(supervisor, fn -> Log.trace("Background supervised task", %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "testTaskSupervisor"}) end)
    end
  end
  defp test_supervision_tree() do
    _ = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}]
    _ = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    _ = Supervisor.start_link(children, options)
    _ = Supervisor.count_children(result)
    _ = Log.trace("Supervisor - Workers: #{(fn -> stats.workers end).()}, Supervisors: #{(fn -> stats.supervisors end).()}", %{:file_name => "Main.hx", :line_number => 271, :class_name => "Main", :method_name => "testSupervisionTree"})
    _ = Supervisor.which_children(result)
    _ = Enum.each(children_list, (fn -> fn item ->
    Log.trace("Child: " <> inspect(Map.get(item, :_0)) <> ", Type: " <> inspect(Map.get(item, :_2)), %{:file_name => "Main.hx", :line_number => 276, :class_name => "Main", :method_name => "testSupervisionTree"})
end end).())
    _ = Supervisor.restart_child(result, "worker1")
    _ = Supervisor.terminate_child(result, "normal")
    _
  end
end
