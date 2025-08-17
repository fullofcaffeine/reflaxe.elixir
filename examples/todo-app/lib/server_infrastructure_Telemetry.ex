defmodule TodoAppWeb.Telemetry do
  @moduledoc """
    TodoAppWeb telemetry supervisor
    Handles application metrics, monitoring, and observability

    This module compiles to TodoAppWeb.Telemetry with proper Phoenix telemetry
    configuration for monitoring web requests, database queries, and custom metrics.
  """
  use Supervisor

  @doc """
  Start the telemetry supervisor
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Telemetry metrics for Phoenix endpoint
      {TelemetryMetricsPrometheus.Core, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Return the list of telemetry metrics to track
  """
  def metrics do
    [
      # Phoenix Endpoint metrics
      Telemetry.Metrics.counter("phoenix.endpoint.start.system_time"),
      Telemetry.Metrics.counter("phoenix.endpoint.stop.duration"),
      Telemetry.Metrics.counter("phoenix.router_dispatch.start.system_time"),
      Telemetry.Metrics.counter("phoenix.router_dispatch.exception.duration"),

      # Database metrics
      Telemetry.Metrics.counter("todoapp.repo.query.total_time"),
      Telemetry.Metrics.counter("todoapp.repo.query.decode_time"),
      Telemetry.Metrics.counter("todoapp.repo.query.query_time"),
      Telemetry.Metrics.counter("todoapp.repo.query.queue_time"),
      Telemetry.Metrics.counter("todoapp.repo.query.idle_time"),

      # LiveView metrics
      Telemetry.Metrics.counter("phoenix.live_view.mount.start.system_time"),
      Telemetry.Metrics.counter("phoenix.live_view.mount.stop.duration"),
      Telemetry.Metrics.counter("phoenix.live_view.handle_event.start.system_time"),
      Telemetry.Metrics.counter("phoenix.live_view.handle_event.stop.duration")
    ]
  end
end