defmodule TestApp.Application do
  use Application

  @moduledoc """
    TestApp.Application module generated from Haxe

     * TypeSafeChildSpec Compilation Test
     *
     * Tests that TypeSafeChildSpec enum constructors compile correctly to their
     * respective child spec formats. This validates the compiler's structure-based
     * detection and direct compilation approach.
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Application.test_type_safe_child_specs()
    Application.test_child_spec_builders()
    Application.test_complex_child_specs()
    Application.test_application_children()
  end

  @doc """
    Test basic TypeSafeChildSpec enum compilation

    This tests the core TypeSafeChildSpec patterns that should compile
    directly to their respective Elixir formats.
  """
  @spec test_type_safe_child_specs() :: nil
  def test_type_safe_child_specs() do
    {Phoenix.PubSub, name: TestApp.PubSub}
    {Phoenix.PubSub, name: CustomName.PubSub}
    App.Repo
    AppWeb.Endpoint
    AppWeb.Telemetry
    App.Repo
    AppWeb.Endpoint
    {:presence, %{"name" => "TestApp.Presence", "pubsub_server" => "TestApp.PubSub"}}
    Log.trace("Basic TypeSafeChildSpec compilation test completed", %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "testTypeSafeChildSpecs"})
  end

  @doc """
    Test TypeSafeChildSpec without builders for now

    Tests direct enum usage since builders aren't implemented yet.
  """
  @spec test_child_spec_builders() :: nil
  def test_child_spec_builders() do
    {Phoenix.PubSub, name: TestApp.PubSub}
    App.Repo
    AppWeb.Endpoint
    AppWeb.Telemetry
    Log.trace("Direct TypeSafeChildSpec test completed", %{"fileName" => "Main.hx", "lineNumber" => 78, "className" => "Main", "methodName" => "testChildSpecBuilders"})
  end

  @doc """
    Test complex child specs with custom modules and configurations

    Tests the Custom variant that handles arbitrary worker modules
    with proper type safety and restart/shutdown policies.
  """
  @spec test_complex_child_specs() :: nil
  def test_complex_child_specs() do
    {:custom, MyComplexWorker, MyComplexWorker.new("complex_worker_args"), :permanent, {:timeout, 5000}}
    {:custom, AnotherWorker, AnotherWorker.new("another_worker_args"), :transient, :infinity}
    Log.trace("Complex TypeSafeChildSpec test completed", %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testComplexChildSpecs"})
  end

  @doc """
    Test complete application child specification

    Tests a realistic Phoenix application setup using TypeSafeChildSpec
    that should compile to proper modern Elixir child spec formats.
  """
  @spec test_application_children() :: nil
  def test_application_children() do
    {Phoenix.PubSub, name: TestApp.PubSub}
    App.Repo
    AppWeb.Endpoint
    AppWeb.Telemetry
    {:presence, %{"name" => "TestApp.Presence", "pubsub_server" => "TestApp.PubSub"}}
    {:custom, BackgroundWorker, BackgroundWorker.new("background_worker_args"), :permanent, {:timeout, 10000}}
    {:custom, TaskSupervisor, TaskSupervisor.new("task_supervisor_args"), :permanent, :infinity}
    {Phoenix.PubSub, name: TestApp.PubSub}
    {:legacy, %{id: legacy_worker, start: {LegacyWorker, :start_link, [%{}]}, restart: :temporary, shutdown: {:timeout, 1000}}}
    Log.trace("Application children test completed", %{"fileName" => "Main.hx", "lineNumber" => 173, "className" => "Main", "methodName" => "testApplicationChildren"})
  end

end
