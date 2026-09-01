defmodule Main do
  defp require_lock(lock, message) do
    if (not apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :wait, [lock, 2])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp test_condition_signal() do
    condition = Sys.Thread.Condition.new()
    ready = Sys.Thread.Lock.new()
    resumed = Sys.Thread.Lock.new()
    allow_final_release = Sys.Thread.Lock.new()
    done = Sys.Thread.Lock.new()
    Sys.Thread.Thread.create(fn ->
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
      apply(Map.get(ready, :__reflaxe_class__) || Map.get(ready, :__struct__), :release, [ready])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :wait, [condition])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
      apply(Map.get(resumed, :__reflaxe_class__) || Map.get(resumed, :__struct__), :release, [resumed])
      apply(Map.get(allow_final_release, :__reflaxe_class__) || Map.get(allow_final_release, :__struct__), :wait, [allow_final_release, nil])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
      apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
    end)
    require_lock(ready, "Condition waiter did not acquire the mutex")
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :signal, [condition])
    if (apply(Map.get(resumed, :__reflaxe_class__) || Map.get(resumed, :__struct__), :wait, [resumed, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition waiter resumed before the signaling owner released the mutex"]
    end
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
    require_lock(resumed, "Condition signal did not resume the waiter")
    if (apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :try_acquire, [condition])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition wait did not restore the recursive mutex hold count"]
    end
    apply(Map.get(allow_final_release, :__reflaxe_class__) || Map.get(allow_final_release, :__struct__), :release, [allow_final_release])
    require_lock(done, "Condition waiter did not release its restored mutex holds")
    if (not apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :try_acquire, [condition])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition mutex stayed locked after the waiter released every hold"]
    end
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
  end
  defp test_condition_broadcast() do
    condition = Sys.Thread.Condition.new()
    ready = Sys.Thread.Lock.new()
    done = Sys.Thread.Lock.new()
    Sys.Thread.Thread.create(fn ->
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
      apply(Map.get(ready, :__reflaxe_class__) || Map.get(ready, :__struct__), :release, [ready])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :wait, [condition])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
      apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
    end)
    Sys.Thread.Thread.create(fn ->
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
      apply(Map.get(ready, :__reflaxe_class__) || Map.get(ready, :__struct__), :release, [ready])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :wait, [condition])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
      apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
    end)
    Sys.Thread.Thread.create(fn ->
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
      apply(Map.get(ready, :__reflaxe_class__) || Map.get(ready, :__struct__), :release, [ready])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :wait, [condition])
      apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
      apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
    end)
    require_lock(ready, "First Condition broadcast waiter did not start")
    require_lock(ready, "Second Condition broadcast waiter did not start")
    require_lock(ready, "Third Condition broadcast waiter did not start")
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :signal, [condition])
    if (apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :wait, [done, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition signal waiter resumed before mutex release"]
    end
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
    require_lock(done, "Condition signal did not resume one waiter")
    if (apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :wait, [done, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition signal resumed more than one waiter"]
    end
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :acquire, [condition])
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :broadcast, [condition])
    if (apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :wait, [done, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Condition broadcast waiter resumed before mutex release"]
    end
    apply(Map.get(condition, :__reflaxe_class__) || Map.get(condition, :__struct__), :release, [condition])
    require_lock(done, "Condition broadcast did not resume the first remaining waiter")
    require_lock(done, "Condition broadcast did not resume the second remaining waiter")
  end
  def main() do
    lock = Sys.Thread.Lock.new()
    if (apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :wait, [lock, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "new Lock should not be released"]
    end
    apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :release, [lock])
    if (not apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :wait, [lock, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "released Lock should allow one waiter"]
    end
    mutex = Sys.Thread.Mutex.new()
    apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :acquire, [mutex])
    apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :acquire, [mutex])
    if (not apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :try_acquire, [mutex])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Mutex should be re-entrant for owner"]
    end
    apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    semaphore = Sys.Thread.Semaphore.new(1)
    if (not apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :try_acquire, [semaphore, nil])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Semaphore first acquire failed"]
    end
    if (apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :try_acquire, [semaphore, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Semaphore second acquire should time out"]
    end
    apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :release, [semaphore])
    apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :acquire, [semaphore])
    apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :release, [semaphore])
    test_condition_signal()
    test_condition_broadcast()
    done = Sys.Thread.Lock.new()
    pool = Sys.Thread.FixedThreadPool.new(2)
    apply(Map.get(pool, :__reflaxe_class__) || Map.get(pool, :__struct__), :run, (fn -> [pool, fn ->
      reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "pool-local"])
      apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
    end] end).())
    if (not apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :wait, [done, 1])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "FixedThreadPool task did not run"]
    end
    apply(Map.get(pool, :__reflaxe_class__) || Map.get(pool, :__struct__), :shutdown, [pool])
    if (not Sys.Thread.FixedThreadPool.get_is_shutdown(pool)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "FixedThreadPool shutdown flag mismatch"]
    end
  end
end
