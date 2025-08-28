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
  @doc "Generated from Haxe main"
  def main() do
    TestApp.Application.test_type_safe_child_specs()

    TestApp.Application.test_child_spec_builders()

    TestApp.Application.test_complex_child_specs()

    TestApp.Application.test_application_children()
  end

  @doc "Generated from Haxe testTypeSafeChildSpecs"
  def test_type_safe_child_specs() do
    _pubsub_children_0 = {Phoenix.PubSub, name: TestApp.PubSub}

    _pubsub_children_1 = {Phoenix.PubSub, name: CustomName.PubSub}

    _module_children_0 = App.Repo

    _module_children_1 = AppWeb.Endpoint

    _module_children_2 = AppWeb.Telemetry

    _configured_children_0 = App.Repo

    _configured_children_1 = AppWeb.Endpoint

    _configured_children_2 = {:presence, %{"name" => "TestApp.Presence", "pubsub_server" => "TestApp.PubSub"}}

    Log.trace("Basic TypeSafeChildSpec compilation test completed", %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "testTypeSafeChildSpecs"})
  end

  @doc "Generated from Haxe testChildSpecBuilders"
  def test_child_spec_builders() do
    _direct_children_0 = {Phoenix.PubSub, name: TestApp.PubSub}

    _direct_children_1 = App.Repo

    _direct_children_2 = AppWeb.Endpoint

    _direct_children_3 = AppWeb.Telemetry

    Log.trace("Direct TypeSafeChildSpec test completed", %{"fileName" => "Main.hx", "lineNumber" => 78, "className" => "Main", "methodName" => "testChildSpecBuilders"})
  end

  @doc "Generated from Haxe testComplexChildSpecs"
  def test_complex_child_specs() do
    _complex_children_0 = {:custom, MyComplexWorker, MyComplexWorker.new("complex_worker_args"), :permanent, ShutdownType.timeout(5000)}

    _complex_children_1 = {:custom, AnotherWorker, AnotherWorker.new("another_worker_args"), :transient, :infinity}

    Log.trace("Complex TypeSafeChildSpec test completed", %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testComplexChildSpecs"})
  end

  @doc "Generated from Haxe testApplicationChildren"
  def test_application_children() do
    _type_safe_children_0 = {Phoenix.PubSub, name: TestApp.PubSub}

    _type_safe_children_1 = App.Repo

    _type_safe_children_2 = AppWeb.Endpoint

    _type_safe_children_3 = AppWeb.Telemetry

    _type_safe_children_4 = {:presence, %{"name" => "TestApp.Presence", "pubsub_server" => "TestApp.PubSub"}}

    _type_safe_children_5 = {:custom, BackgroundWorker, BackgroundWorker.new("background_worker_args"), :permanent, ShutdownType.timeout(10000)}

    _type_safe_children_6 = {:custom, TaskSupervisor, TaskSupervisor.new("task_supervisor_args"), :permanent, :infinity}

    _mixed_children_0 = {Phoenix.PubSub, name: TestApp.PubSub}

    _mixed_children_1 = {:legacy, %{id: legacy_worker, start: {LegacyWorker, :start_link, [%{}]}, restart: :temporary, shutdown: ShutdownType.timeout(1000)}}

    Log.trace("Application children test completed", %{"fileName" => "Main.hx", "lineNumber" => 173, "className" => "Main", "methodName" => "testApplicationChildren"})
  end

end
