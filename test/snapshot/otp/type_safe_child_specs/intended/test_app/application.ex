defmodule TestApp.Application do
  use Application
  defp test_type_safe_child_specs() do
    _ = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _ = {Phoenix.PubSub, [name: CustomName.PubSub]}
    _ = config = nil
    if (not Kernel.is_nil(config)), do: {:module_with_config, "TestApp.Repo", config}, else: {:module_ref, "TestApp.Repo"}
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    _ = config = [%{:key => "database", :value => "test_db"}, %{:key => "pool_size", :value => 5}]
    if (not Kernel.is_nil(config)), do: {:module_with_config, "TestApp.Repo", config}, else: {:module_ref, "TestApp.Repo"}
    _ = TestAppWeb.Endpoint
    _ = args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    if (not Kernel.is_nil(args) and length(args) > 0), do: {:module_with_args, "TestApp.Presence", args}, else: {:module_ref, "TestApp.Presence"}
    _ = Log.trace("Basic TypeSafeChildSpec compilation test completed", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testTypeSafeChildSpecs"})
    _
  end
  defp test_child_spec_builders() do
    _ = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _ = config = nil
    if (not Kernel.is_nil(config)), do: {:module_with_config, "TestApp.Repo", config}, else: {:module_ref, "TestApp.Repo"}
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    _ = Log.trace("Direct TypeSafeChildSpec test completed", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testChildSpecBuilders"})
    _
  end
  defp test_complex_child_specs() do
    _ = %{:id => "MyComplexWorker", :start => {MyComplexWorker, :start_link, ["complex_worker_args"]}, :restart => {:permanent}, :shutdown => 5000, :type => {:worker}}
    _ = %{:id => "AnotherWorker", :start => {AnotherWorker, :start_link, ["another_worker_args"]}, :restart => {:transient}, :shutdown => {:infinity}, :type => {:worker}}
    _ = Log.trace("Complex TypeSafeChildSpec test completed", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testComplexChildSpecs"})
    _
  end
  defp test_application_children() do
    _ = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _ = config = [%{:key => "database", :value => "test_app_dev"}, %{:key => "pool_size", :value => 10}, %{:key => "timeout", :value => 15000}]
    if (not Kernel.is_nil(config)), do: {:module_with_config, "TestApp.Repo", config}, else: {:module_ref, "TestApp.Repo"}
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    _ = args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    if (not Kernel.is_nil(args) and length(args) > 0), do: {:module_with_args, "TestApp.Presence", args}, else: {:module_ref, "TestApp.Presence"}
    _ = %{:id => "BackgroundWorker", :start => {BackgroundWorker, :start_link, ["background_worker_args"]}, :restart => {:permanent}, :shutdown => 10000, :type => {:worker}}
    _ = %{:id => "TaskSupervisor", :start => {TaskSupervisor, :start_link, ["task_supervisor_args"]}, :restart => {:permanent}, :shutdown => {:infinity}, :type => {:supervisor}}
    _ = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _ = %{:id => "legacy_worker", :start => {LegacyWorker, :start_link, [%{}]}, :restart => {:temporary}, :shutdown => 1000, :type => {:worker}}
    _ = Log.trace("Application children test completed", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "testApplicationChildren"})
    _
  end
end
