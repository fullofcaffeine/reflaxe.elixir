defmodule Main do
  defp test_supervisor() do
    children = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => {:permanent}, :type => {:supervisor}}]
    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    result = Supervisor.start_link(children, options)
    supervisor = result
    children_list = Supervisor.which_children(supervisor)
    counts = Supervisor.count_children(supervisor)
    _ = Supervisor.restart_child(supervisor, "worker1")
    _ = Supervisor.terminate_child(supervisor, "worker2")
    _ = Supervisor.delete_child(supervisor, "worker2")
    new_child = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}
    _ = Supervisor.start_child(supervisor, new_child)
    stats = Supervisor.count_children(supervisor)
    if (Process.process.alive?(supervisor)), do: nil
    _ = Process.process.exit(supervisor, "normal")
  end
  defp test_task() do
    task = Task.task.async((fn -> fn ->
      Process.process.sleep(100)
      42
    end end).())
    result = Task.task.await(task)
    slow_task = Task.task.async((fn -> fn ->
      Process.process.sleep(5000)
      "slow"
    end end).())
    yield_result = Task.task.yield(slow_task, 100)
    if (Kernel.is_nil(yield_result)) do
      Task.task.shutdown(slow_task)
    end
    _ = Task.task.start(fn -> nil end)
    linked_result = Task.task.start_link(fn -> nil end)
    tasks = [Task.task.async(fn -> nil end), Task.task.async(fn -> 2 end), Task.task.async(fn -> 3 end)]
    results = Task.task.yield_many(tasks)
    _ = Enum.each(results, (fn -> fn task_result ->
    if (task_result.result != nil), do: nil
end end).())
    task = Task.task.async(fn -> "quick" end)
    quick_result = _ = Task.task.await(task)
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    _ = Enum.each(funs, (fn -> fn fun ->
    [].push(Task.task.async(fun))
end end).())
    tasks = []
    concurrent_results = _ = Enum.each(tasks, (fn -> fn task ->
    [].push(Task.task.await(task))
end end).())
    []
    task = Task.task.async((fn -> fn ->
      Process.process.sleep(50)
      "timed"
    end end).())
    result = Task.task.yield(task, 100)
    timed_result = if (Kernel.is_nil(result)) do
      _ = Task.task.shutdown(task)
      nil
    else
      (case result do
        0 ->
          value = elem(result, 1)
          value
        1 -> nil
      end)
    end
    _ = Task.task.start(fn -> nil end)
    stream = Task.task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    supervisor_result = Supervisor.task.supervisor.start_link()
    if (supervisor_result._0 == "ok") do
      supervisor = supervisor_result._1
      task = Supervisor.task.supervisor.async(supervisor, fn -> "supervised" end)
      result = Task.task.await(task)
      nolink_task = Supervisor.task.supervisor.async_nolink(supervisor, fn -> "not linked" end)
      _ = Task.task.await(nolink_task)
      _ = Supervisor.task.supervisor.start_child(supervisor, fn -> nil end)
      children = Supervisor.task.supervisor.children(supervisor)
      stream = Supervisor.task.supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      task = Supervisor.task.supervisor.async(supervisor, fn -> "helper result" end)
      supervised_result = _ = Task.task.await(task)
      funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      g = 0
      _ = Enum.map(funs, (fn -> fn item ->
  fun = funs[_g1]
  _g1 + 1
  _g = Enum.concat(_g, [Supervisor.task.supervisor.async(supervisor, fun)])
end end).())
      tasks = []
      concurrent_results = g = 0
      _ = Enum.map(tasks, (fn -> fn item ->
  task = tasks[_g1]
  _g1 + 1
  _g = Enum.concat(_g, [Task.task.await(task)])
end end).())
      []
      _ = Supervisor.task.supervisor.start_child(supervisor, fn -> nil end)
    end
  end
  defp test_supervision_tree() do
    children = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}]
    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    result = Supervisor.start_link(children, options)
    supervisor = result
    stats = Supervisor.count_children(supervisor)
    children_list = Supervisor.which_children(supervisor)
    _ = Enum.each(children_list, (fn -> fn _ ->
    nil
end end).())
    _ = Supervisor.restart_child(supervisor, "worker1")
    _ = Supervisor.terminate_child(supervisor, "normal")
  end
end
