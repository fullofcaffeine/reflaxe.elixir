defmodule Main do
  defp main() do
    test_supervisor()
    test_task()
    test_task_supervisor()
    test_supervision_tree()
  end
  defp test_supervisor() do
    children = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => :permanent, :type => :worker}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => :temporary, :type => :worker}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => :permanent, :type => :supervisor}]
    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    result = Supervisor.start_link(children, options)
    supervisor = result
    _children_list = Supervisor.which_children(supervisor)
    _counts = Supervisor.count_children(supervisor)
    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.terminate_child(supervisor, "worker2")
    Supervisor.delete_child(supervisor, "worker2")
    new_child = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => :transient, :type => :worker}
    Supervisor.start_child(supervisor, new_child)
    stats = Supervisor.count_children(supervisor)
    Log.trace("Active workers: " <> stats[:workers] <> ", Supervisors: " <> stats[:supervisors], %{:fileName => "Main.hx", :lineNumber => 89, :className => "Main", :methodName => "testSupervisor"})
    if (Process.alive?(supervisor)) do
      Log.trace("Supervisor is running", %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "testSupervisor"})
    end
    Process.exit(supervisor, "normal")
  end
  defp test_task() do
    task = Task.async(fn ->
  Process.sleep(100)
  42
end)
    result = Task.await(task)
    Log.trace("Async result: " <> result, %{:fileName => "Main.hx", :lineNumber => 113, :className => "Main", :methodName => "testTask"})
    slow_task = Task.async(fn ->
  Process.sleep(5000)
  "slow"
end)
    yield_result = Task.yield(slow_task, 100)
    if (yield_result == nil) do
      Log.trace("Task timed out", %{:fileName => "Main.hx", :lineNumber => 123, :className => "Main", :methodName => "testTask"})
      Task.shutdown(slow_task)
    end
    {:"Task.start", fn -> Log.trace("Background task running", %{:fileName => "Main.hx", :lineNumber => 129, :className => "Main", :methodName => "testTask"}) end}
    linked_result = {:"Task.start_link", fn -> Log.trace("Linked task running", %{:fileName => "Main.hx", :lineNumber => 134, :className => "Main", :methodName => "testTask"}) end}
    tasks = [Task.async(fn -> 1 end), Task.async(fn -> 2 end), Task.async(fn -> 3 end)]
    results = Task.yield_many(tasks)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, results, :ok}, fn _, {acc_g, acc_results, acc_state} ->
  if (acc_g < acc_results.length) do
    task_result = results[g]
    acc_g = acc_g + 1
    if (task_result[:result] != nil) do
      Log.trace("Task result: " <> Std.string(task_result[:result]), %{:fileName => "Main.hx", :lineNumber => 148, :className => "Main", :methodName => "testTask"})
    end
    {:cont, {acc_g, acc_results, acc_state}}
  else
    {:halt, {acc_g, acc_results, acc_state}}
  end
end)
    task = Task.async(fn -> "quick" end)
    quick_result = Task.await(task)
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    g = []
    g1 = 0
    tasks = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {funs, g1, :ok}, fn _, {acc_funs, acc_g1, acc_state} ->
  fun = funs[g1]
  if acc_g1 < acc_funs.length do
    acc_g1 = acc_g1 + 1
    g.push(Task.async(fun))
    {:cont, {acc_funs, acc_g1, acc_state}}
  else
    {:halt, {acc_funs, acc_g1, acc_state}}
  end
end)
g
    g = []
    g1 = 0
    concurrent_results = tasks
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, tasks, :ok}, fn _, {acc_g1, acc_tasks, acc_state} ->
  task = tasks[g1]
  if (acc_g1 < acc_tasks.length) do
    acc_g1 = acc_g1 + 1
    g.push(Task.await(task))
    {:cont, {acc_g1, acc_tasks, acc_state}}
  else
    {:halt, {acc_g1, acc_tasks, acc_state}}
  end
end)
g
    task = Task.async(fn ->
  Process.sleep(50)
  "timed"
end)
    result = Task.yield(task, 100)
    timed_result = if result == nil do
  Task.shutdown(task)
  nil
else
  case (result.elem(0)) do
    0 ->
      g = result.elem(1)
      value = g
      value
    1 ->
      g = result.elem(1)
      nil
  end
end
    {:"Task.start", fn -> Log.trace("Fire and forget", %{:fileName => "Main.hx", :lineNumber => 169, :className => "Main", :methodName => "testTask"}) end}
    stream = Task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    supervisor_result = Task.Supervisor.start_link()
    if (supervisor_result[:_0] == "ok") do
      supervisor = supervisor_result[:_1]
      task = Task.Supervisor.async(supervisor, fn -> "supervised" end)
      result = Task.await(task)
      Log.trace("Supervised task result: " <> result, %{:fileName => "Main.hx", :lineNumber => 192, :className => "Main", :methodName => "testTaskSupervisor"})
      nolink_task = Task.Supervisor.async_nolink(supervisor, fn -> "not linked" end)
      Task.await(nolink_task)
      Task.Supervisor.start_child(supervisor, fn -> Log.trace("Supervised child task", %{:fileName => "Main.hx", :lineNumber => 202, :className => "Main", :methodName => "testTaskSupervisor"}) end)
      children = Task.Supervisor.children(supervisor)
      Log.trace("Supervised tasks count: " <> children.length, %{:fileName => "Main.hx", :lineNumber => 207, :className => "Main", :methodName => "testTaskSupervisor"})
      stream = Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      task = Task.Supervisor.async(supervisor, fn -> "helper result" end)
      supervised_result = Task.await(task)
      supervisor = supervisor
      funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      g = []
      g1 = 0
      tasks = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, funs, :ok}, fn _, {acc_g1, acc_funs, acc_state} ->
  fun = funs[g1]
  if acc_g1 < acc_funs.length do
    acc_g1 = acc_g1 + 1
    g.push(Task.Supervisor.async(supervisor, fun))
    {:cont, {acc_g1, acc_funs, acc_state}}
  else
    {:halt, {acc_g1, acc_funs, acc_state}}
  end
end)
g
      g = []
      g1 = 0
      concurrent_results = tasks
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, tasks, :ok}, fn _, {acc_g1, acc_tasks, acc_state} ->
  task = tasks[g1]
  if (acc_g1 < acc_tasks.length) do
    acc_g1 = acc_g1 + 1
    g.push(Task.await(task))
    {:cont, {acc_g1, acc_tasks, acc_state}}
  else
    {:halt, {acc_g1, acc_tasks, acc_state}}
  end
end)
g
      Task.Supervisor.start_child(supervisor, fn -> Log.trace("Background supervised task", %{:fileName => "Main.hx", :lineNumber => 228, :className => "Main", :methodName => "testTaskSupervisor"}) end)
    end
  end
  defp test_supervision_tree() do
    children = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => :permanent, :type => :worker}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => :temporary, :type => :worker}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => :transient, :type => :worker}]
    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    result = Supervisor.start_link(children, options)
    supervisor = result
    stats = Supervisor.count_children(supervisor)
    Log.trace("Supervisor - Workers: " <> stats[:workers] <> ", Supervisors: " <> stats[:supervisors], %{:fileName => "Main.hx", :lineNumber => 271, :className => "Main", :methodName => "testSupervisionTree"})
    children_list = Supervisor.which_children(supervisor)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, children_list, :ok}, fn _, {acc_g, acc_children_list, acc_state} ->
  if (acc_g < acc_children_list.length) do
    child = children_list[g]
    acc_g = acc_g + 1
    Log.trace("Child: " <> Std.string(child._0) <> ", Type: " <> Std.string(child._2), %{:fileName => "Main.hx", :lineNumber => 276, :className => "Main", :methodName => "testSupervisionTree"})
    {:cont, {acc_g, acc_children_list, acc_state}}
  else
    {:halt, {acc_g, acc_children_list, acc_state}}
  end
end)
    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.terminate_child(supervisor, "normal")
  end
end