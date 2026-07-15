defmodule Main do
  defp assert_true(label, condition) do
    if (not condition) do
      Kernel.raise("OTP contract failed: #{label}")
    end
  end
  defp assert_equals(label, expected, actual) do
    if (expected != actual) do
      Kernel.raise("OTP contract failed: #{label}")
    end
  end
  defp wait_until_stopped(pid) do
    attempts = 0
    {_attempts} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {attempts}, fn _, {acc_attempts} ->
      try do
        if (Process.alive?(pid) and acc_attempts < 50) do
          Process.sleep(2)
          acc_attempts = acc_attempts + 1
          {:cont, {acc_attempts}}
        else
          {:halt, {acc_attempts}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_attempts}}
        :throw, :continue ->
          {:cont, {acc_attempts}}
      end
    end)
    assert_true("spawned process stops after an exit signal", not Process.alive?(pid))
  end
  defp test_local_process_lifecycle() do
    current = Kernel.self()
    assert_true("Process.self returns a live pid", Process.alive?(current))
    child = Kernel.spawn(fn -> Process.sleep(200) end)
    assert_true("Process.spawn starts a live local process", Process.alive?(child))
    Process.exit(child, :shutdown)
    wait_until_stopped(child)
  end
  defp test_task_success_and_timeout() do
    completed = Task.async(fn -> 42 end)
    assert_equals("Task.async and Task.await return the function result", 42, Task.await(completed))
    slow = Task.async(fn ->
      Process.sleep(200)
      7
    end)
    task = slow
    slow_pid = task.pid
    early = Task.yield(slow, 1)
    assert_true("Task.yield returns null before a slow task completes", Kernel.is_nil(early))
    Task.shutdown(slow)
    wait_until_stopped(slow_pid)
  end
  defp test_agent_state_and_stop() do
    _started = (case Agent.start(fn -> 10 end) do
      {:ok, agent} ->
        assert_equals("Agent.get reads initial state", 10, Agent.get(agent, fn value -> value end))
        Agent.update(agent, fn value -> value + 5 end)
        assert_equals("Agent.update changes state", 15, Agent.get(agent, fn value -> value end))
        Agent.cast(agent, fn value -> value + 2 end)
        assert_equals("Agent.cast is observed by a later call from the same process", 17, Agent.get(agent, fn value -> value end))
        Agent.stop(agent)
        assert_true("Agent.stop ends the process", not Process.alive?(agent))
      {:error, reason} ->
        Kernel.raise("OTP contract failed: Agent.start returned #{reason}")
    end)
  end
  def main() do
    test_local_process_lifecycle()
    test_task_success_and_timeout()
    test_agent_state_and_stop()
  end
end
