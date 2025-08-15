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

  @doc """
    Test Supervisor extern functions

  """
  @spec test_supervisor() :: nil
  def test_supervisor() do
    children = [%{:id => "worker1", :start => %{_0 => "MyWorker", _1 => "start_link", _2 => [%{:name => "worker1"}]}, :restart => "permanent", :type => "worker"}, %{:id => "worker2", :start => %{_0 => "MyWorker", _1 => "start_link", _2 => [%{:name => "worker2"}]}, :restart => "temporary", :type => "worker"}, %{:id => "sub_supervisor", :start => %{_0 => "SubSupervisor", _1 => "start_link", _2 => [%{}]}, :restart => "permanent", :type => "supervisor"}]
    options = %{:strategy => "one_for_one", :max_restarts => 5, :max_seconds => 10}
    result = Supervisor.start_link(children, options)
    if (result._0 == "ok") do
      supervisor = result._1
      Supervisor.which_children(supervisor)
      Supervisor.count_children(supervisor)
      Supervisor.restart_child(supervisor, "worker1")
      Supervisor.terminate_child(supervisor, "worker2")
      Supervisor.delete_child(supervisor, "worker2")
      new_child = %{:id => "dynamic", :start => %{_0 => "DynamicWorker", _1 => "start_link", _2 => [%{}]}, :restart => "transient", :type => "worker"}
      Supervisor.start_child(supervisor, new_child)
      temp_struct = nil
      counts = Supervisor.count_children(supervisor)
      temp_struct = %{specs => counts.get("specs"), active => counts.get("active"), supervisors => counts.get("supervisors"), workers => counts.get("workers")}
      stats = temp_struct
      Log.trace("Active workers: " <> Integer.to_string(stats.workers) <> ", Supervisors: " <> Integer.to_string(stats.supervisors), %{fileName => "Main.hx", lineNumber => 83, className => "Main", methodName => "testSupervisor"})
      if (Process.alive?(supervisor)), do: Log.trace("Supervisor is running", %{fileName => "Main.hx", lineNumber => 87, className => "Main", methodName => "testSupervisor"}), else: nil
      Supervisor.stop(supervisor)
    end
  end

  @doc """
    Test Task extern functions

  """
  @spec test_task() :: nil
  def test_task() do
    task = Task.async(fn  -> Process.sleep(100)
    42 end)
    result = Task.await(task)
    Log.trace("Async result: " <> result, %{fileName => "Main.hx", lineNumber => 107, className => "Main", methodName => "testTask"})
    slow_task = Task.async(fn  -> Process.sleep(5000)
    "slow" end)
    yield_result = Task.yield(slow_task, 100)
    if (yield_result == nil) do
      Log.trace("Task timed out", %{fileName => "Main.hx", lineNumber => 117, className => "Main", methodName => "testTask"})
      Task.shutdown(slow_task)
    end
    Task.start(fn  -> Log.trace("Background task running", %{fileName => "Main.hx", lineNumber => 123, className => "Main", methodName => "testTask"}) end)
    Task.start_link(fn  -> Log.trace("Linked task running", %{fileName => "Main.hx", lineNumber => 128, className => "Main", methodName => "testTask"}) end)
    tasks = [Task.async(fn  -> 1 end), Task.async(fn  -> 2 end), Task.async(fn  -> 3 end)]
    results = Task.yield_many(tasks)
    _g = 0
    Enum.map(results, fn item -> task_result = Enum.at(results, _g)
    _g = _g + 1
    if (task_result._1 != nil && task_result._1._0 == "ok"), do: Log.trace("Task result: " <> Std.string(task_result._1._1), %{fileName => "Main.hx", lineNumber => 141, className => "Main", methodName => "testTask"}), else: nil end)
    temp_var = nil
    task = Task.async(fn  -> "quick" end)
    temp_var = Task.await(task)
    temp_var
    temp_array = nil
    funs = [fn  -> "a" end, fn  -> "b" end, fn  -> "c" end]
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.map(funs, fn item -> fun = Enum.at(funs, _g)
    _g = _g + 1
    _g ++ [Task.async(fun)] end)
    temp_array1 = _g
    tasks = temp_array1
    _g = []
    _g = 0
    Enum.map(tasks, fn item -> task = Enum.at(tasks, _g)
    _g = _g + 1
    _g ++ [Task.await(task)] end)
    temp_array = _g
    temp_maybe_maybe_string = nil
    task = Task.async(fn  -> Process.sleep(50)
    "timed" end)
    result = Task.yield(task, 100)
    if (result != nil && result._0 == "ok") do
      temp_maybe_maybe_string = result._1
    else
      Task.shutdown(task)
      temp_maybe_maybe_string = nil
    end
    temp_maybe_maybe_string
    Task.start(fn  -> Log.trace("Fire and forget", %{fileName => "Main.hx", lineNumber => 162, className => "Main", methodName => "testTask"}) end)
    Task.async_stream([1, 2, 3, 4, 5], fn x -> x * 2 end)
  end

  @doc """
    Test Task.Supervisor extern functions

  """
  @spec test_task_supervisor() :: nil
  def test_task_supervisor() do
    supervisor_result = Task.Supervisor.start_link()
    if (supervisor_result._0 == "ok") do
      supervisor = supervisor_result._1
      task = Task.Supervisor.async(supervisor, fn  -> "supervised" end)
      result = Task.await(task)
      Log.trace("Supervised task result: " <> result, %{fileName => "Main.hx", lineNumber => 185, className => "Main", methodName => "testTaskSupervisor"})
      nolink_task = Task.Supervisor.async_nolink(supervisor, fn  -> "not linked" end)
      Task.await(nolink_task)
      Task.Supervisor.start_child(supervisor, fn  -> Log.trace("Supervised child task", %{fileName => "Main.hx", lineNumber => 195, className => "Main", methodName => "testTaskSupervisor"}) end)
      children = Task.Supervisor.children(supervisor)
      Log.trace("Supervised tasks count: " <> Integer.to_string(length(children)), %{fileName => "Main.hx", lineNumber => 200, className => "Main", methodName => "testTaskSupervisor"})
      Task.Supervisor.async_stream(supervisor, [10, 20, 30], fn x -> x + 1 end)
      temp_var = nil
      task = Task.Supervisor.async(supervisor, fn  -> "helper result" end)
      temp_var = Task.await(task)
      temp_var
      temp_array = nil
      supervisor = supervisor
      funs = [fn  -> 100 end, fn  -> 200 end, fn  -> 300 end]
      temp_array1 = nil
      _g = []
      _g = 0
      Enum.map(funs, fn item -> fun = Enum.at(funs, _g)
      _g = _g + 1
      _g ++ [Task.Supervisor.async(supervisor, fun)] end)
      temp_array1 = _g
      tasks = temp_array1
      _g = []
      _g = 0
      Enum.map(tasks, fn item -> task = Enum.at(tasks, _g)
      _g = _g + 1
      _g ++ [Task.await(task)] end)
      temp_array = _g
      temp_array
      Task.Supervisor.start_child(supervisor, fn  -> Log.trace("Background supervised task", %{fileName => "Main.hx", lineNumber => 221, className => "Main", methodName => "testTaskSupervisor"}) end)
    end
  end

  @doc """
    Test complete supervision tree

  """
  @spec test_supervision_tree() :: nil
  def test_supervision_tree() do
    children = [%{:id => "worker1", :start => %{_0 => "Worker1", _1 => "start_link", _2 => [%{}]}, :restart => "permanent", :type => "worker"}, %{:id => "worker2", :start => %{_0 => "Worker2", _1 => "start_link", _2 => [%{}]}, :restart => "temporary", :type => "worker"}, %{:id => "worker3", :start => %{_0 => "Worker3", _1 => "start_link", _2 => [%{}]}, :restart => "transient", :type => "worker"}]
    options = %{:strategy => "one_for_all", :max_restarts => 10, :max_seconds => 60}
    result = Supervisor.start_link(children, options)
    if (result._0 == "ok") do
      supervisor = result._1
      temp_struct = nil
      counts = Supervisor.count_children(supervisor)
      temp_struct = %{specs => counts.get("specs"), active => counts.get("active"), supervisors => counts.get("supervisors"), workers => counts.get("workers")}
      stats = temp_struct
      Log.trace("Supervisor - Workers: " <> Integer.to_string(stats.workers) <> ", Supervisors: " <> Integer.to_string(stats.supervisors), %{fileName => "Main.hx", lineNumber => 264, className => "Main", methodName => "testSupervisionTree"})
      children_list = Supervisor.which_children(supervisor)
      _g = 0
      Enum.map(children_list, fn item -> child = Enum.at(children_list, _g)
      _g = _g + 1
      Log.trace("Child: " <> Std.string(child._0) <> ", Type: " <> child._2, %{fileName => "Main.hx", lineNumber => 269, className => "Main", methodName => "testSupervisionTree"}) end)
      Supervisor.restart_child(supervisor, "worker1")
      Supervisor.stop(supervisor, "normal")
    end
  end

end
