defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * OTP Supervision Patterns Test
 * Tests Supervisor, Task, and Task.Supervisor extern definitions
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.testSupervisor()
Main.testTask()
Main.testTaskSupervisor()
Main.testSupervisionTree()
  end

  @doc "
     * Test Supervisor extern functions
     "
  @spec test_supervisor() :: nil
  def test_supervisor() do
    temp_map = nil
restart = "permanent"
if (restart == nil), do: restart = "permanent", else: nil
temp_map1 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "MyWorker", _1: "start_link", _2: [%{name: "worker1"}]})
_g.set("restart", restart)
_g.set("type", "worker")
temp_map1 = _g
spec = temp_map1
spec.set("id", "worker1")
"worker1"
temp_map = spec
temp_map2 = nil
restart = "temporary"
if (restart == nil), do: restart = "permanent", else: nil
temp_map3 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "MyWorker", _1: "start_link", _2: [%{name: "worker2"}]})
_g.set("restart", restart)
_g.set("type", "worker")
temp_map3 = _g
spec = temp_map3
spec.set("id", "worker2")
"worker2"
temp_map2 = spec
temp_map4 = nil
restart = "permanent"
if (restart == nil), do: restart = "permanent", else: nil
temp_map5 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "SubSupervisor", _1: "start_link", _2: [%{}]})
_g.set("restart", restart)
_g.set("type", "supervisor")
temp_map5 = _g
spec = temp_map5
spec.set("id", "sub_supervisor")
"sub_supervisor"
temp_map4 = spec
children = [temp_map, temp_map2, temp_map4]
temp_map6 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("strategy", "one_for_one")
_g.set("max_restarts", 5)
_g.set("max_seconds", 10)
temp_map6 = _g
options = temp_map6
result = Supervisor.start_link(children, options)
if (result._0 == "ok") do
  supervisor = result._1
  children_list = Supervisor.which_children(supervisor)
  counts = Supervisor.count_children(supervisor)
  Supervisor.restart_child(supervisor, "worker1")
  Supervisor.terminate_child(supervisor, "worker2")
  Supervisor.delete_child(supervisor, "worker2")
  temp_map7 = nil
  restart = "transient"
  if (restart == nil), do: restart = "permanent", else: nil
  temp_map8 = nil
  _g = Haxe.Ds.StringMap.new()
  _g.set("start", %{_0: "DynamicWorker", _1: "start_link", _2: [%{}]})
  _g.set("restart", restart)
  _g.set("type", "worker")
  temp_map8 = _g
  spec = temp_map8
  spec.set("id", "dynamic")
  "dynamic"
  temp_map7 = spec
  new_child = temp_map7
  Supervisor.start_child(supervisor, new_child)
  temp_struct = nil
  counts2 = Supervisor.count_children(supervisor)
  temp_struct = %{specs: counts2.get("specs"), active: counts2.get("active"), supervisors: counts2.get("supervisors"), workers: counts2.get("workers")}
  stats = temp_struct
  Log.trace("Active workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{fileName: "Main.hx", lineNumber: 59, className: "Main", methodName: "testSupervisor"})
  if (Process.alive?(supervisor)), do: Log.trace("Supervisor is running", %{fileName: "Main.hx", lineNumber: 63, className: "Main", methodName: "testSupervisor"}), else: nil
  Supervisor.stop(supervisor)
end
  end

  @doc "
     * Test Task extern functions
     "
  @spec test_task() :: nil
  def test_task() do
    task = Task.async(fn  -> Process.sleep(100)
42 end)
result = Task.await(task)
Log.trace("Async result: " <> result, %{fileName: "Main.hx", lineNumber: 83, className: "Main", methodName: "testTask"})
slow_task = Task.async(fn  -> Process.sleep(5000)
"slow" end)
yield_result = Task.yield(slow_task, 100)
if (yield_result == nil) do
  Log.trace("Task timed out", %{fileName: "Main.hx", lineNumber: 93, className: "Main", methodName: "testTask"})
  Task.shutdown(slow_task)
end
Task.start(fn  -> Log.trace("Background task running", %{fileName: "Main.hx", lineNumber: 99, className: "Main", methodName: "testTask"}) end)
linked_result = Task.start_link(fn  -> Log.trace("Linked task running", %{fileName: "Main.hx", lineNumber: 104, className: "Main", methodName: "testTask"}) end)
tasks = [Task.async(fn  -> 1 end), Task.async(fn  -> 2 end), Task.async(fn  -> 3 end)]
results = Task.yield_many(tasks)
_g = 0
Enum.map(results, fn item -> if (task_result._1 != nil && task_result._1._0 == "ok"), do: Log.trace("Task result: " + Std.string(item._1._1), %{fileName: "Main.hx", lineNumber: 117, className: "Main", methodName: "testTask"}), else: item end)
temp_var = nil
task2 = Task.async(fn  -> "quick" end)
temp_var = Task.await(task2)
quick_result = temp_var
temp_array = nil
funs = [fn  -> "a" end, fn  -> "b" end, fn  -> "c" end]
temp_array1 = nil
_g = []
_g1 = 0
Enum.map(funs, fn item -> Task.Task.async(item) end)
temp_array1 = _g
tasks2 = temp_array1
_g = []
_g1 = 0
Enum.map(tasks2, fn item -> Task.Task.await(item) end)
temp_array = _g
concurrent_results = temp_array
temp_maybe_maybe_string = nil
task2 = Task.async(fn  -> Process.sleep(50)
"timed" end)
result2 = Task.yield(task2, 100)
if (result2 != nil && result2._0 == "ok") do
  temp_maybe_maybe_string = result2._1
else
  Task.shutdown(task2)
  temp_maybe_maybe_string = nil
end
timed_result = temp_maybe_maybe_string
Task.start(fn  -> Log.trace("Fire and forget", %{fileName: "Main.hx", lineNumber: 138, className: "Main", methodName: "testTask"}) end)
stream = Task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end

  @doc "
     * Test Task.Supervisor extern functions
     "
  @spec test_task_supervisor() :: nil
  def test_task_supervisor() do
    supervisor_result = Task.Supervisor.start_link()
if (supervisor_result._0 == "ok") do
  supervisor = supervisor_result._1
  task = Task.Supervisor.async(supervisor, fn  -> "supervised" end)
  result = Task.await(task)
  Log.trace("Supervised task result: " <> result, %{fileName: "Main.hx", lineNumber: 161, className: "Main", methodName: "testTaskSupervisor"})
  nolink_task = Task.Supervisor.async_nolink(supervisor, fn  -> "not linked" end)
  Task.await(nolink_task)
  Task.Supervisor.start_child(supervisor, fn  -> Log.trace("Supervised child task", %{fileName: "Main.hx", lineNumber: 171, className: "Main", methodName: "testTaskSupervisor"}) end)
  children = Task.Supervisor.children(supervisor)
  Log.trace("Supervised tasks count: " <> length(children), %{fileName: "Main.hx", lineNumber: 176, className: "Main", methodName: "testTaskSupervisor"})
  stream = Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
  temp_var = nil
  task2 = Task.Supervisor.async(supervisor, fn  -> "helper result" end)
  temp_var = Task.await(task2)
  supervised_result = temp_var
  temp_array = nil
  supervisor2 = supervisor
  funs = [fn  -> 100 end, fn  -> 200 end, fn  -> 300 end]
  temp_array1 = nil
  _g = []
  _g1 = 0
  Enum.map(funs, fn item -> Supervisor.Task.Supervisor.async(item, fun) end)
  temp_array1 = _g
  tasks = temp_array1
  _g = []
  _g1 = 0
  Enum.map(tasks, fn item -> Task.Task.await(item) end)
  temp_array = _g
  concurrent_results = temp_array
  Task.Supervisor.start_child(supervisor, fn  -> Log.trace("Background supervised task", %{fileName: "Main.hx", lineNumber: 197, className: "Main", methodName: "testTaskSupervisor"}) end)
end
  end

  @doc "
     * Test complete supervision tree
     "
  @spec test_supervision_tree() :: nil
  def test_supervision_tree() do
    temp_map = nil
restart = "permanent"
if (restart == nil), do: restart = "permanent", else: nil
temp_map1 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "Worker1", _1: "start_link", _2: [%{}]})
_g.set("restart", restart)
_g.set("type", "worker")
temp_map1 = _g
spec = temp_map1
spec.set("id", "worker1")
"worker1"
temp_map = spec
temp_map2 = nil
restart = "temporary"
if (restart == nil), do: restart = "permanent", else: nil
temp_map3 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "Worker2", _1: "start_link", _2: [%{}]})
_g.set("restart", restart)
_g.set("type", "worker")
temp_map3 = _g
spec = temp_map3
spec.set("id", "worker2")
"worker2"
temp_map2 = spec
temp_map4 = nil
restart = "transient"
if (restart == nil), do: restart = "permanent", else: nil
temp_map5 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("start", %{_0: "Worker3", _1: "start_link", _2: [%{}]})
_g.set("restart", restart)
_g.set("type", "worker")
temp_map5 = _g
spec = temp_map5
spec.set("id", "worker3")
"worker3"
temp_map4 = spec
children = [temp_map, temp_map2, temp_map4]
temp_map6 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("strategy", "one_for_all")
_g.set("max_restarts", 10)
_g.set("max_seconds", 60)
temp_map6 = _g
options = temp_map6
result = Supervisor.start_link(children, options)
if (result._0 == "ok") do
  supervisor = result._1
  temp_struct = nil
  counts = Supervisor.count_children(supervisor)
  temp_struct = %{specs: counts.get("specs"), active: counts.get("active"), supervisors: counts.get("supervisors"), workers: counts.get("workers")}
  stats = temp_struct
  Log.trace("Supervisor - Workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{fileName: "Main.hx", lineNumber: 225, className: "Main", methodName: "testSupervisionTree"})
  children_list = Supervisor.which_children(supervisor)
  _g = 0
  Enum.map(children_list, fn item -> "Child: " + Std.string(item._0) + ", Type: " + item._2 end)
  Supervisor.restart_child(supervisor, "worker1")
  Supervisor.stop(supervisor, "normal")
end
  end

end
