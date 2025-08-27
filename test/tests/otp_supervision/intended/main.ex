defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * OTP Supervision Patterns Test
     * Tests Supervisor, Task, and Task.Supervisor extern definitions
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_supervisor()

    Main.test_task()

    Main.test_task_supervisor()

    Main.test_supervision_tree()
  end

  @doc "Generated from Haxe testSupervisor"
  def test_supervisor() do
    children = [%{id: worker1, start: {MyWorker, :start_link, [%{name: worker1}]}, restart: :permanent, type: :worker}, %{id: worker2, start: {MyWorker, :start_link, [%{name: worker2}]}, restart: :temporary, type: :worker}, %{id: sub_supervisor, start: {SubSupervisor, :start_link, [%{}]}, restart: :permanent, type: :supervisor}]

    options = [strategy: :one_for_one, name: App.Supervisor]

    result = Supervisor.start_link(children, options)

    if ((result.0 == "ok")) do
      supervisor = result.1
      _children_list = Supervisor.which_children(supervisor)
      _counts = Supervisor.count_children(supervisor)
      Supervisor.restart_child(supervisor, "worker1")
      Supervisor.terminate_child(supervisor, "worker2")
      Supervisor.delete_child(supervisor, "worker2")
      new_child = %{id: dynamic, start: {DynamicWorker, :start_link, [%{}]}, restart: :transient, type: :worker}
      Supervisor.start_child(supervisor, new_child)
      stats = Supervisor.count_children(supervisor)
      Log.trace("Active workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{"fileName" => "Main.hx", "lineNumber" => 89, "className" => "Main", "methodName" => "testSupervisor"})
      if Process.alive?(Process, supervisor), do: Log.trace("Supervisor is running", %{"fileName" => "Main.hx", "lineNumber" => 93, "className" => "Main", "methodName" => "testSupervisor"}), else: nil
      Process.exit(Process, supervisor, "normal")
    else
      nil
    end
  end

  @doc "Generated from Haxe testTask"
  def test_task() do
    temp_var = nil
    temp_array1 = nil
    temp_array = nil
    temp_maybe_maybe_string = nil

    task = Task.async(Task, fn  -> Process.sleep(Process, 100)
    42 end)

    result = Task.await(Task, task)

    Log.trace("Async result: " <> result, %{"fileName" => "Main.hx", "lineNumber" => 114, "className" => "Main", "methodName" => "testTask"})

    slow_task = Task.async(Task, fn  -> Process.sleep(Process, 5000)
    "slow" end)

    yield_result = Task.yield(Task, slow_task, 100)

    if ((yield_result == nil)) do
      Log.trace("Task timed out", %{"fileName" => "Main.hx", "lineNumber" => 124, "className" => "Main", "methodName" => "testTask"})
      Task.shutdown(Task, slow_task)
    else
      nil
    end

    Task.start(Task, fn  -> Log.trace("Background task running", %{"fileName" => "Main.hx", "lineNumber" => 130, "className" => "Main", "methodName" => "testTask"}) end)

    _linked_result = Task.start_link(Task, fn  -> Log.trace("Linked task running", %{"fileName" => "Main.hx", "lineNumber" => 135, "className" => "Main", "methodName" => "testTask"}) end)

    tasks = [Task.async(Task, fn  -> 1 end), Task.async(Task, fn  -> 2 end), Task.async(Task, fn  -> 3 end)]

    results = Task.yield_many(Task, tasks)

    g_counter = 0
    Enum.filter(results, fn item -> (item.1 != nil) && (item.1.0 == "ok") end)

    temp_var = nil

    task = Task.async(Task, fn  -> "quick" end)
    temp_var = Task.await(Task, task)

    _quick_result = temp_var

    funs = [fn  -> "a" end, fn  -> "b" end, fn  -> "c" end]

    g_array = []
    g_counter = 0
    Enum.map(funs, fn item -> Task.async(Task, item) end)
    temp_array1 = g_array

    tasks = temp_array1

    g_array = []
    g_counter = 0
    Enum.map(tasks2, fn item -> Task.await(Task, task) end)
    temp_array = g_array

    temp_maybe_maybe_string = nil

    task = Task.async(Task, fn  -> Process.sleep(Process, 50)
    "timed" end)
    result = Task.yield(Task, task, 100)
    if (((result != nil) && (result.0 == "ok"))) do
      temp_maybe_maybe_string = result.1
    else
      Task.shutdown(Task, task)
      temp_maybe_maybe_string = nil
    end

    _timed_result = temp_maybe_maybe_string

    Task.start(Task, fn  -> Log.trace("Fire and forget", %{"fileName" => "Main.hx", "lineNumber" => 169, "className" => "Main", "methodName" => "testTask"}) end)

    _stream = Task.async_stream(Task, [1, 2, 3, 4, 5], fn x -> (x * 2) end)
  end

  @doc "Generated from Haxe testTaskSupervisor"
  def test_task_supervisor() do
    temp_var = nil
    temp_array1 = nil
    temp_array = nil

    supervisor_result = Task.Supervisor.start_link(Task.Supervisor)

    if ((supervisor_result.0 == "ok")) do
      supervisor = supervisor_result.1
      task = Task.Supervisor.async(Task.Supervisor, supervisor, fn  -> "supervised" end)
      result = Task.await(Task, task)
      Log.trace("Supervised task result: " <> result, %{"fileName" => "Main.hx", "lineNumber" => 192, "className" => "Main", "methodName" => "testTaskSupervisor"})
      nolink_task = Task.Supervisor.async_nolink(Task.Supervisor, supervisor, fn  -> "not linked" end)
      Task.await(Task, nolink_task)
      Task.Supervisor.start_child(Task.Supervisor, supervisor, fn  -> Log.trace("Supervised child task", %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "testTaskSupervisor"}) end)
      children = Task.Supervisor.children(Task.Supervisor, supervisor)
      Log.trace("Supervised tasks count: " <> to_string(children.length), %{"fileName" => "Main.hx", "lineNumber" => 207, "className" => "Main", "methodName" => "testTaskSupervisor"})
      _stream = Task.Supervisor.async_stream(Task.Supervisor, supervisor, [10, 20, 30], fn x -> (x + 1) end)
      task = Task.Supervisor.async(Task.Supervisor, supervisor, fn  -> "helper result" end)
      temp_var = Task.await(Task, task)
      _supervised_result = temp_var
      supervisor = supervisor
      funs = [fn  -> 100 end, fn  -> 200 end, fn  -> 300 end]
      g_array = []
      g_counter = 0
      Enum.map(funs, fn item -> Task.Supervisor.async(Task.Supervisor, supervisor, item) end)
      temp_array1 = g_array
      tasks = temp_array1
      g_array = []
      g_counter = 0
      Enum.map(tasks, fn item -> Task.await(Task, task) end)
      temp_array = g_array
      _concurrent_results = temp_array
      Task.Supervisor.start_child(Task.Supervisor, supervisor, fn  -> Log.trace("Background supervised task", %{"fileName" => "Main.hx", "lineNumber" => 228, "className" => "Main", "methodName" => "testTaskSupervisor"}) end)
    else
      nil
    end
  end

  @doc "Generated from Haxe testSupervisionTree"
  def test_supervision_tree() do
    children = [%{id: worker1, start: {Worker1, :start_link, [%{}]}, restart: :permanent, type: :worker}, %{id: worker2, start: {Worker2, :start_link, [%{}]}, restart: :temporary, type: :worker}, %{id: worker3, start: {Worker3, :start_link, [%{}]}, restart: :transient, type: :worker}]

    options = [strategy: :one_for_all, name: App.Supervisor]

    result = Supervisor.start_link(children, options)

    if ((result.0 == "ok")) do
      supervisor = result.1
      stats = Supervisor.count_children(supervisor)
      Log.trace("Supervisor - Workers: " <> stats.workers <> ", Supervisors: " <> stats.supervisors, %{"fileName" => "Main.hx", "lineNumber" => 271, "className" => "Main", "methodName" => "testSupervisionTree"})
      children_list = Supervisor.which_children(supervisor)
      g_counter = 0
      Enum.each(g_array, fn child -> 
        Log.trace("Child: " <> Std.string(child.0) <> ", Type: " <> Std.string(child.2), %{"fileName" => "Main.hx", "lineNumber" => 276, "className" => "Main", "methodName" => "testSupervisionTree"})
      end)
      Supervisor.restart_child(supervisor, "worker1")
      Supervisor.terminate_child(supervisor, "normal")
    else
      nil
    end
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
