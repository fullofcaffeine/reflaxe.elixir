defmodule HaxeTimings do
  @moduledoc """
  Optional process-local timing collection for Haxe/Mix integration phases.

  Timings are disabled by default. Set `HAXE_TIMINGS=1` (or `true`/`yes`/`y`) to
  collect phase durations and print a short summary at the end of the Mix task.
  """

  @enabled_env "HAXE_TIMINGS"
  @timings_key {__MODULE__, :timings}
  @started_at_key {__MODULE__, :started_at}

  @doc """
  Returns true when phase timing output is enabled for the current process.
  """
  @spec enabled?() :: boolean()
  def enabled? do
    case System.get_env(@enabled_env) do
      nil ->
        false

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> truthy?()
    end
  end

  @doc """
  Resets process-local timing state.
  """
  @spec reset() :: :ok
  def reset do
    if enabled?() do
      Process.put(@timings_key, [])
      Process.put(@started_at_key, monotonic_now())
    end

    :ok
  end

  @doc """
  Measures a phase when timings are enabled, otherwise just executes `fun`.
  """
  @spec measure(binary(), (-> result)) :: result when result: var
  def measure(label, fun) when is_binary(label) and is_function(fun, 0) do
    if enabled?() do
      started_at = monotonic_now()

      try do
        fun.()
      after
        record(label, elapsed_ms(started_at))
      end
    else
      fun.()
    end
  end

  @doc """
  Records a phase duration in milliseconds.
  """
  @spec record(binary(), number()) :: :ok
  def record(label, duration_ms) when is_binary(label) and is_number(duration_ms) do
    if enabled?() do
      timings = Process.get(@timings_key, [])
      Process.put(@timings_key, [{label, duration_ms} | timings])
    end

    :ok
  end

  @doc """
  Prints a summary of collected phases when timings are enabled.
  """
  @spec report(binary()) :: :ok
  def report(context) when is_binary(context) do
    if enabled?() do
      timings =
        @timings_key
        |> Process.get([])
        |> Enum.reverse()

      Mix.shell().info("== Haxe timings: #{context} ==")

      Enum.each(timings, fn {label, duration_ms} ->
        Mix.shell().info("  #{label}: #{format_ms(duration_ms)} ms")
      end)

      case Process.get(@started_at_key) do
        nil ->
          :ok

        started_at ->
          Mix.shell().info("  total wall: #{format_ms(elapsed_ms(started_at))} ms")
      end
    end

    :ok
  end

  defp truthy?(value) do
    value in ["1", "true", "yes", "y"]
  end

  defp monotonic_now do
    System.monotonic_time(:native)
  end

  defp elapsed_ms(started_at) do
    System.convert_time_unit(monotonic_now() - started_at, :native, :microsecond) / 1000
  end

  defp format_ms(duration_ms) do
    :erlang.float_to_binary(duration_ms * 1.0, decimals: 1)
  end
end
