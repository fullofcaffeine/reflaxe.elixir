defmodule ManagedReferenceSpike.Benchmark do
  alias ManagedReferenceSpike.HybridHeap
  alias ManagedReferenceSpike.Native

  def run do
    iterations = 50_000

    native_reference = Native.new_object(0)

    native_microseconds =
      elapsed(fn ->
        Enum.each(1..iterations, fn _ -> Native.increment(native_reference, 1) end)
      end)

    {:ok, hybrid_heap} = HybridHeap.start_link()
    hybrid_reference = HybridHeap.new(hybrid_heap, 0)

    hybrid_microseconds =
      elapsed(fn ->
        Enum.each(1..iterations, fn _ -> HybridHeap.increment(hybrid_reference, 1) end)
      end)

    IO.puts("toolchain otp=#{System.otp_release()} elixir=#{System.version()}")
    IO.puts("iterations=#{iterations}")
    IO.puts("native_increment_us=#{native_microseconds}")
    IO.puts("hybrid_increment_us=#{hybrid_microseconds}")
    IO.puts("hybrid_over_native=#{Float.round(hybrid_microseconds / native_microseconds, 2)}x")

    GenServer.stop(hybrid_heap)
  end

  defp elapsed(operation) do
    started = System.monotonic_time()
    operation.()

    (System.monotonic_time() - started)
    |> System.convert_time_unit(:native, :microsecond)
  end
end

ManagedReferenceSpike.Benchmark.run()
