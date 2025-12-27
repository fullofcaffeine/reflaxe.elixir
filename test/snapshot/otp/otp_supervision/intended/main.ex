defmodule Main do
  defp test_supervisor() do
    children = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => {:permanent}, :type => {:supervisor}}]
    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    result = supervisor.start_link(children, options)
    supervisor = result
    children_list = supervisor.which_children(supervisor)
    counts = supervisor.count_children(supervisor)
    _ = supervisor.restart_child(supervisor, "worker1")
    _ = supervisor.terminate_child(supervisor, "worker2")
    _ = supervisor.delete_child(supervisor, "worker2")
    new_child = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}
    _ = supervisor.start_child(supervisor, new_child)
    stats = supervisor.count_children(supervisor)
    if (Process.alive?(supervisor)), do: nil
    _ = Process.exit(supervisor, "normal")
  end
  defp test_task() do
    task = task.async(fn ->
      _ = Process.sleep(100)
      42
    end)
    result = task.await(task)
    slow_task = task.async(fn ->
      _ = Process.sleep(5000)
      "slow"
    end)
    yield_result = task.yield(slow_task, 100)
    if (Kernel.is_nil(yield_result)) do
      task.shutdown(slow_task)
    end
    _ = task.start(fn -> nil end)
    linked_result = task.start_link(fn -> nil end)
    tasks = [task.async(fn -> nil end), task.async(fn -> 2 end), task.async(fn -> 3 end)]
    results = task.yield_many(tasks)
    _g = 0
    _ = Enum.each(results, fn task_result ->
  if (not Kernel.is_nil(task_result.result)), do: nil
end)
    task = task.async(fn -> "quick" end)
    quick_result = _ = task.await(task)
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    g_value = 0
    _ = Enum.each(funs, fn fun -> [task.async(fun)] end)
    tasks = []
    concurrent_results = g_value = 0
    _ = Enum.each(tasks, fn task -> [task.await(task)] end)
    []
    task = task.async(fn ->
      _ = Process.sleep(50)
      "timed"
    end)
    result = task.yield(task, 100)
    timed_result = if (Kernel.is_nil(result)) do
      _ = task.shutdown(task)
      nil
    else
      (case result do
        0 ->
          value = elem(result, 1)
          value
        1 -> nil
      end)
    end
    _ = task.start(fn -> nil end)
    stream = task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    supervisor_result = Task.Supervisor.start_link()
    if (supervisor_result._0 == "ok") do
      supervisor = supervisor_result._1
      task = Task.Supervisor.async(supervisor, fn -> "supervised" end)
      result = task.await(task)
      nolink_task = Task.Supervisor.async_nolink(supervisor, fn -> "not linked" end)
      _ = task.await(nolink_task)
      _ = Task.Supervisor.start_child(supervisor, fn -> nil end)
      children = Task.Supervisor.children(supervisor)
      stream = Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      task = Task.Supervisor.async(supervisor, fn -> "helper result" end)
      supervised_result = _ = task.await(task)
      funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      g = []
      g_value = 0
      _g = Enum.reduce(funs, g, fn fun, g_acc -> Enum.concat(g_acc, [Task.Supervisor.async(supervisor, fun)]) end)
      tasks = g
      concurrent_results = g = []
      g_value = 0
      _g = Enum.reduce(tasks, g, fn task, g_acc -> Enum.concat(g_acc, [task.await(task)]) end)
      g
      _ = Task.Supervisor.start_child(supervisor, fn -> nil end)
    end
  end
  defp test_supervision_tree() do
    children = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}]
    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    result = supervisor.start_link(children, options)
    supervisor = result
    stats = supervisor.count_children(supervisor)
    children_list = supervisor.which_children(supervisor)
    _g = 0
    _ = Enum.each(children_list, fn _ -> nil end)
    _ = supervisor.restart_child(supervisor, "worker1")
    _ = supervisor.terminate_child(supervisor, "normal")
  end
end
