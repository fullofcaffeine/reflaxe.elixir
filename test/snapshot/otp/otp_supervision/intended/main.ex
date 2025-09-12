defmodule Main do
  def main() do
    test_supervisor()
    test_task()
    test_task_supervisor()
    test_supervision_tree()
  end
  defp test_supervisor() do
    children = [%{:id => "worker1", :start => {MyWorker, :start_link, [%{:name => "worker1"}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {MyWorker, :start_link, [%{:name => "worker2"}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "sub_supervisor", :start => {SubSupervisor, :start_link, [%{}]}, :restart => {:permanent}, :type => {:supervisor}}]
    options = [strategy: :one_for_one, max_restarts: 5, max_seconds: 10]
    result = Supervisor.start_link(children, options)
    supervisor = result
    _children_list = Supervisor.which_children(supervisor)
    _counts = Supervisor.count_children(supervisor)
    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.terminate_child(supervisor, "worker2")
    Supervisor.delete_child(supervisor, "worker2")
    new_child = %{:id => "dynamic", :start => {DynamicWorker, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}
    Supervisor.start_child(supervisor, new_child)
    stats = Supervisor.count_children(supervisor)
    Log.trace("Active workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "testSupervisor"})
    if (Process.process.alive?(supervisor)) do
      Log.trace("Supervisor is running", %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testSupervisor"})
    end
    Process.process.exit(supervisor, "normal")
  end
  defp test_task() do
    task = Task.task.async(fn ->
  Process.process.sleep(100)
  42
end)
    result = Task.task.await(task)
    Log.trace("Async result: " <> result, %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testTask"})
    slow_task = Task.task.async(fn ->
  Process.process.sleep(5000)
  "slow"
end)
    yield_result = Task.task.yield(slow_task, 100)
    if (yield_result == nil) do
      Log.trace("Task timed out", %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "testTask"})
      Task.task.shutdown(slow_task)
    end
    Task.task.start(fn -> Log.trace("Background task running", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testTask"}) end)
    linked_result = Task.task.start_link(fn -> Log.trace("Linked task running", %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "testTask"}) end)
    tasks = [Task.task.async(fn -> 1 end), Task.task.async(fn -> 2 end), Task.task.async(fn -> 3 end)]
    results = Task.task.yield_many(tasks)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {results, g, :ok}, fn _, {acc_results, acc_g, acc_state} ->
  if (acc_g < length(acc_results)) do
    task_result = results[g]
    acc_g = acc_g + 1
    if (Map.get(task_result, :result) != nil) do
      Log.trace("Task result: " <> Std.string(task_result.result), %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testTask"})
    end
    {:cont, {acc_results, acc_g, acc_state}}
  else
    {:halt, {acc_results, acc_g, acc_state}}
  end
end)
    task = Task.task.async(fn -> "quick" end)
    quick_result = Task.task.await(task)
    funs = [fn -> "a" end, fn -> "b" end, fn -> "c" end]
    g = []
    g1 = 0
    tasks = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {funs, g1, :ok}, fn _, {acc_funs, acc_g1, acc_state} ->
  fun = funs[g1]
  if acc_g1 < length(acc_funs) do
    acc_g1 = acc_g1 + 1
    g = g ++ [Task.task.async(fun)]
    {:cont, {acc_funs, acc_g1, acc_state}}
  else
    {:halt, {acc_funs, acc_g1, acc_state}}
  end
end)
g
    g = []
    g1 = 0
    concurrent_results = tasks
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {tasks, g1, :ok}, fn _, {acc_tasks, acc_g1, acc_state} ->
  task = tasks[g1]
  if (acc_g1 < length(acc_tasks)) do
    acc_g1 = acc_g1 + 1
    g = g ++ [Task.task.await(task)]
    {:cont, {acc_tasks, acc_g1, acc_state}}
  else
    {:halt, {acc_tasks, acc_g1, acc_state}}
  end
end)
g
    task = Task.task.async(fn ->
  Process.process.sleep(50)
  "timed"
end)
    result = Task.task.yield(task, 100)
    timed_result = if result == nil do
  Task.task.shutdown(task)
  nil
else
  case (result) do
    0 ->
      g = elem(result, 1)
      value = g
      value
    1 ->
      g = elem(result, 1)
      nil
  end
end
    Task.task.start(fn -> Log.trace("Fire and forget", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "testTask"}) end)
    stream = Task.task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end
  defp test_task_supervisor() do
    supervisor_result = Task.Supervisor.task._supervisor.start_link()
    if (elem(supervisor_result, -1) == "ok") do
      supervisor = elem(supervisor_result, 0)
      task = Task.Supervisor.task._supervisor.async(supervisor, fn -> "supervised" end)
      result = Task.task.await(task)
      Log.trace("Supervised task result: " <> result, %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "testTaskSupervisor"})
      nolink_task = Task.Supervisor.task._supervisor.async_nolink(supervisor, fn -> "not linked" end)
      Task.task.await(nolink_task)
      Task.Supervisor.task._supervisor.start_child(supervisor, fn -> Log.trace("Supervised child task", %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "testTaskSupervisor"}) end)
      children = Task.Supervisor.task._supervisor.children(supervisor)
      Log.trace("Supervised tasks count: " <> Kernel.to_string(length(children)), %{:file_name => "Main.hx", :line_number => 207, :class_name => "Main", :method_name => "testTaskSupervisor"})
      stream = Task.Supervisor.task._supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      task = Task.Supervisor.task._supervisor.async(supervisor, fn -> "helper result" end)
      supervised_result = Task.task.await(task)
      supervisor = supervisor
      funs = [fn -> 100 end, fn -> 200 end, fn -> 300 end]
      g = []
      g1 = 0
      tasks = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {funs, g1, :ok}, fn _, {acc_funs, acc_g1, acc_state} ->
  fun = funs[g1]
  if acc_g1 < length(acc_funs) do
    acc_g1 = acc_g1 + 1
    g = g ++ [Task.Supervisor.task._supervisor.async(supervisor, fun)]
    {:cont, {acc_funs, acc_g1, acc_state}}
  else
    {:halt, {acc_funs, acc_g1, acc_state}}
  end
end)
g
      g = []
      g1 = 0
      concurrent_results = tasks
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {tasks, g1, :ok}, fn _, {acc_tasks, acc_g1, acc_state} ->
  task = tasks[g1]
  if (acc_g1 < length(acc_tasks)) do
    acc_g1 = acc_g1 + 1
    g = g ++ [Task.task.await(task)]
    {:cont, {acc_tasks, acc_g1, acc_state}}
  else
    {:halt, {acc_tasks, acc_g1, acc_state}}
  end
end)
g
      Task.Supervisor.task._supervisor.start_child(supervisor, fn -> Log.trace("Background supervised task", %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "testTaskSupervisor"}) end)
    end
  end
  defp test_supervision_tree() do
    children = [%{:id => "worker1", :start => {Worker1, :start_link, [%{}]}, :restart => {:permanent}, :type => {:worker}}, %{:id => "worker2", :start => {Worker2, :start_link, [%{}]}, :restart => {:temporary}, :type => {:worker}}, %{:id => "worker3", :start => {Worker3, :start_link, [%{}]}, :restart => {:transient}, :type => {:worker}}]
    options = [strategy: :one_for_all, max_restarts: 10, max_seconds: 60]
    result = Supervisor.start_link(children, options)
    supervisor = result
    stats = Supervisor.count_children(supervisor)
    Log.trace("Supervisor - Workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{:file_name => "Main.hx", :line_number => 271, :class_name => "Main", :method_name => "testSupervisionTree"})
    children_list = Supervisor.which_children(supervisor)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {children_list, g, :ok}, fn _, {acc_children_list, acc_g, acc_state} ->
  if (acc_g < length(acc_children_list)) do
    child = children_list[g]
    acc_g = acc_g + 1
    Log.trace("Child: " <> Std.string(child._0) <> ", Type: " <> Std.string(child._2), %{:file_name => "Main.hx", :line_number => 276, :class_name => "Main", :method_name => "testSupervisionTree"})
    {:cont, {acc_children_list, acc_g, acc_state}}
  else
    {:halt, {acc_children_list, acc_g, acc_state}}
  end
end)
    Supervisor.restart_child(supervisor, "worker1")
    Supervisor.terminate_child(supervisor, "normal")
  end
end