defmodule Main do
  def main() do
    _ = test_supervisor()
    _ = test_task()
    _ = test_task_supervisor()
    _ = test_supervision_tree()
  end
  defp test_supervisor() do
    children = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => {:permanent}, :type => {:supervisor}}]
    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    result = Supervisor.start_link(children, options)
    supervisor = result
    _children_list = Supervisor.which_children(supervisor)
    _counts = Supervisor.count_children(supervisor)
    _ = Supervisor.restart_child(supervisor, "worker1")
    _ = Supervisor.terminate_child(supervisor, "worker2")
    _ = Supervisor.delete_child(supervisor, "worker2")
    new_child = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}
    _ = Supervisor.start_child(supervisor, new_child)
    _stats = Supervisor.count_children(supervisor)
    if (Process.alive?(supervisor)), do: nil
    _ = Process.exit(supervisor, "normal")
  end
  defp test_task() do
    task = Task.async(fn ->
      _ = Process.sleep(100)
      42
    end)
    result = Task.await(task)
    slow_task = Task.async(fn ->
      _ = Process.sleep(5000)
      "slow"
    end)
    yield_result = Task.yield(slow_task, 100)
    if (Kernel.is_nil(yield_result)) do
      Task.shutdown(slow_task)
    end
    _ = Task.start(fn -> nil end)
    _linked_result = Task.start_link(fn -> nil end)
    tasks = [Task.async(fn -> nil end), Task.async(fn -> 2 end), Task.async(fn -> 3 end)]
    results = Task.yield_many(tasks)
    g = 0
    _ = Enum.each(results, fn task_result ->
  if (not Kernel.is_nil(task_result.result)), do: nil
end)
    task = Task.async(fn -> "quick" end)
    _quick_result = _ = Task.await(task)
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    g = []
    g = Enum.reduce(funs, g, fn fun, g_acc -> Enum.concat(g_acc, [Task.async(fun)]) end)
    tasks = g
    g = []
    g = Enum.reduce(tasks, g, fn task, g_acc -> Enum.concat(g_acc, [Task.await(task)]) end)
    _concurrent_results = g
    task = Task.async(fn ->
      _ = Process.sleep(50)
      "timed"
    end)
    result = Task.yield(task, 100)
    _timed_result = if (Kernel.is_nil(result)) do
      _ = Task.shutdown(task)
      nil
    else
      (case result do
        0 ->
          value = elem(result, 1)
          value
        1 -> nil
      end)
    end
    _ = Task.start(fn -> nil end)
    _stream = Task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    supervisor_result = Task.Supervisor.start_link()
    if (supervisor_result._0 == "ok") do
      supervisor = supervisor_result._1
      task = Task.Supervisor.async(supervisor, fn -> "supervised" end)
      _result = Task.await(task)
      nolink_task = Task.Supervisor.async_nolink(supervisor, fn -> "not linked" end)
      _ = Task.await(nolink_task)
      _ = Task.Supervisor.start_child(supervisor, fn -> nil end)
      children = Task.Supervisor.children(supervisor)
      _stream = Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      task = Task.Supervisor.async(supervisor, fn -> "helper result" end)
      _supervised_result = _ = Task.await(task)
      funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      g = []
      g = Enum.reduce(funs, g, fn fun, g_acc -> Enum.concat(g_acc, [Task.Supervisor.async(supervisor, fun)]) end)
      tasks = g
      g = []
      g = Enum.reduce(tasks, g, fn task, g_acc -> Enum.concat(g_acc, [Task.await(task)]) end)
      _concurrent_results = g
      _ = Task.Supervisor.start_child(supervisor, fn -> nil end)
    end
  end
  defp test_supervision_tree() do
    children = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}]
    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    result = Supervisor.start_link(children, options)
    supervisor = result
    _stats = Supervisor.count_children(supervisor)
    children_list = Supervisor.which_children(supervisor)
    _g = 0
    _ = Enum.each(children_list, fn _ -> nil end)
    _ = Supervisor.restart_child(supervisor, "worker1")
    _ = Supervisor.terminate_child(supervisor, "normal")
  end
end
