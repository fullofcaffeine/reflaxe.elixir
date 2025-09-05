defmodule TestApp.Application do
  use Application
  defp main() do
    test_type_safe_child_specs()
    test_child_spec_builders()
    test_complex_child_specs()
    test_application_children()
  end
  defp test_type_safe_child_specs() do
    pubsub_children_1 = nil
    pubsub_children_0 = nil
    pubsub_children_0 = {Phoenix.PubSub, [name: :"TestApp.PubSub"]}
    pubsub_children_1 = {Phoenix.PubSub, [name: :"CustomName.PubSub"]}
    module_children_2 = nil
    module_children_1 = nil
    module_children_0 = nil
    config = nil
    module_children_0 = if config != nil, do: {TestApp.Repo, config}, else: TestApp.Repo
    module_children_1 = TestAppWeb.Endpoint
    module_children_2 = TestApp.Telemetry
    configured_children_2 = nil
    configured_children_1 = nil
    configured_children_0 = nil
    config = [%{:key => "database", :value => "test_db"}, %{:key => "pool_size", :value => 5}]
    configured_children_0 = if config != nil, do: {TestApp.Repo, config}, else: TestApp.Repo
    configured_children_1 = TestAppWeb.Endpoint
    args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    configured_children_2 = if args != nil && args.length > 0, do: {TestApp.Presence, args}, else: TestApp.Presence
    Log.trace("Basic TypeSafeChildSpec compilation test completed", %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "testTypeSafeChildSpecs"})
  end
  defp test_child_spec_builders() do
    direct_children_3 = nil
    direct_children_2 = nil
    direct_children_1 = nil
    direct_children_0 = nil
    direct_children_0 = {Phoenix.PubSub, [name: :"TestApp.PubSub"]}
    config = nil
    direct_children_1 = if config != nil, do: {TestApp.Repo, config}, else: TestApp.Repo
    direct_children_2 = TestAppWeb.Endpoint
    direct_children_3 = TestApp.Telemetry
    Log.trace("Direct TypeSafeChildSpec test completed", %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "testChildSpecBuilders"})
  end
  defp test_complex_child_specs() do
    complex_children_1 = nil
    complex_children_0 = nil
    complex_children_0 = %{:id => "MyComplexWorker", :start => {MyComplexWorker, :start_link, ["complex_worker_args"]}, :restart => :permanent, :shutdown => {:Timeout, 5000}, :type => :worker}
    complex_children_1 = %{:id => "AnotherWorker", :start => {AnotherWorker, :start_link, ["another_worker_args"]}, :restart => :transient, :shutdown => :infinity, :type => :worker}
    Log.trace("Complex TypeSafeChildSpec test completed", %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "testComplexChildSpecs"})
  end
  defp test_application_children() do
    type_safe_children_6 = nil
    type_safe_children_5 = nil
    type_safe_children_4 = nil
    type_safe_children_3 = nil
    type_safe_children_2 = nil
    type_safe_children_1 = nil
    type_safe_children_0 = nil
    type_safe_children_0 = {Phoenix.PubSub, [name: :"TestApp.PubSub"]}
    config = [%{:key => "database", :value => "test_app_dev"}, %{:key => "pool_size", :value => 10}, %{:key => "timeout", :value => 15000}]
    type_safe_children_1 = if config != nil, do: {TestApp.Repo, config}, else: TestApp.Repo
    type_safe_children_2 = TestAppWeb.Endpoint
    type_safe_children_3 = TestApp.Telemetry
    args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    type_safe_children_4 = if args != nil && args.length > 0, do: {TestApp.Presence, args}, else: TestApp.Presence
    type_safe_children_5 = %{:id => "BackgroundWorker", :start => {BackgroundWorker, :start_link, ["background_worker_args"]}, :restart => :permanent, :shutdown => {:Timeout, 10000}, :type => :worker}
    type_safe_children_6 = %{:id => "TaskSupervisor", :start => {TaskSupervisor, :start_link, ["task_supervisor_args"]}, :restart => :permanent, :shutdown => :infinity, :type => :supervisor}
    mixed_children_1 = nil
    mixed_children_0 = nil
    mixed_children_0 = {Phoenix.PubSub, [name: :"TestApp.PubSub"]}
    mixed_children_1 = %{:id => "legacy_worker", :start => {LegacyWorker, :start_link, [%{}]}, :restart => :temporary, :shutdown => {:Timeout, 1000}, :type => :worker}
    Log.trace("Application children test completed", %{:fileName => "Main.hx", :lineNumber => 172, :className => "Main", :methodName => "testApplicationChildren"})
  end
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: TestApp.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end
end