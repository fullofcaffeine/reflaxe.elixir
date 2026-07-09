defmodule Main do
  def main() do
    lock = Sys.Thread.Lock.new()
    if (apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :wait, [lock, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "new Lock should not be released"]
    end
    _ = apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :release, [lock])
    if (not apply(Map.get(lock, :__reflaxe_class__) || Map.get(lock, :__struct__), :wait, [lock, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "released Lock should allow one waiter"]
    end
    mutex = Sys.Thread.Mutex.new()
    _ = apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :acquire, [mutex])
    _ = apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :acquire, [mutex])
    if (not apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :try_acquire, [mutex])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Mutex should be re-entrant for owner"]
    end
    _ = apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    _ = apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    _ = apply(Map.get(mutex, :__reflaxe_class__) || Map.get(mutex, :__struct__), :release, [mutex])
    semaphore = Sys.Thread.Semaphore.new(1)
    if (not apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :try_acquire, [semaphore, nil])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Semaphore first acquire failed"]
    end
    if (apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :try_acquire, [semaphore, 0])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Semaphore second acquire should time out"]
    end
    _ = apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :release, [semaphore])
    _ = apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :acquire, [semaphore])
    _ = apply(Map.get(semaphore, :__reflaxe_class__) || Map.get(semaphore, :__struct__), :release, [semaphore])
    done = Sys.Thread.Lock.new()
    pool = Sys.Thread.FixedThreadPool.new(2)
    _ =
      apply(Map.get(pool, :__reflaxe_class__) || Map.get(pool, :__struct__), :run, (fn -> [pool, fn ->
        reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
        _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "pool-local"])
        _ = apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :release, [done])
      end] end).())
    if (not apply(Map.get(done, :__reflaxe_class__) || Map.get(done, :__struct__), :wait, [done, 1])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "FixedThreadPool task did not run"]
    end
    _ = apply(Map.get(pool, :__reflaxe_class__) || Map.get(pool, :__struct__), :shutdown, [pool])
    if (not Sys.Thread.FixedThreadPool.get_is_shutdown(pool)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "FixedThreadPool shutdown flag mismatch"]
    end
  end
end
