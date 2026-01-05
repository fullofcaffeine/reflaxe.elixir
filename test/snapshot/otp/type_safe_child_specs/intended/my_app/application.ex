defmodule TestApp.Application do
  use Application
  def main() do
    _ = test_type_safe_child_specs()
    _ = test_child_spec_builders()
    _ = test_complex_child_specs()
    _ = test_application_children()
  end
  defp test_type_safe_child_specs() do
    _pubsub_children_0 = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _pubsub_children_1 = {Phoenix.PubSub, [name: CustomName.PubSub]}
    config = nil
    _module_children_0 = if (not Kernel.is_nil(config)), do: {TestApp.Repo, config}, else: TestApp.Repo
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    config = [%{:key => "database", :value => "test_db"}, %{:key => "pool_size", :value => 5}]
    _configured_children_0 = if (not Kernel.is_nil(config)), do: {TestApp.Repo, config}, else: TestApp.Repo
    _ = TestAppWeb.Endpoint
    args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    _configured_children_2 = if (not Kernel.is_nil(args) and length(args) > 0), do: {TestApp.Presence, args}, else: TestApp.Presence
    nil
  end
  defp test_child_spec_builders() do
    _direct_children_0 = {Phoenix.PubSub, [name: TestApp.PubSub]}
    config = nil
    _direct_children_1 = if (not Kernel.is_nil(config)), do: {TestApp.Repo, config}, else: TestApp.Repo
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    nil
  end
  defp test_complex_child_specs() do
    _complex_children_0 = %{:id => "MyComplexWorker", :start => {MyComplexWorker, :start_link, ["complex_worker_args"]}, :restart => {:permanent}, :shutdown => {:timeout, 5000}, :type => {:worker}}
    _complex_children_1 = %{:id => "AnotherWorker", :start => {AnotherWorker, :start_link, ["another_worker_args"]}, :restart => {:transient}, :shutdown => {:infinity}, :type => {:worker}}
    nil
  end
  defp test_application_children() do
    _type_safe_children_0 = {Phoenix.PubSub, [name: TestApp.PubSub]}
    config = [%{:key => "database", :value => "test_app_dev"}, %{:key => "pool_size", :value => 10}, %{:key => "timeout", :value => 15000}]
    _type_safe_children_1 = if (not Kernel.is_nil(config)), do: {TestApp.Repo, config}, else: TestApp.Repo
    _ = TestAppWeb.Endpoint
    _ = TestApp.Telemetry
    args = [%{:name => "TestApp.Presence", :pubsub_server => "TestApp.PubSub"}]
    _type_safe_children_4 = if (not Kernel.is_nil(args) and length(args) > 0), do: {TestApp.Presence, args}, else: TestApp.Presence
    _type_safe_children_5 = %{:id => "BackgroundWorker", :start => {BackgroundWorker, :start_link, ["background_worker_args"]}, :restart => {:permanent}, :shutdown => {:timeout, 10000}, :type => {:worker}}
    _type_safe_children_6 = %{:id => "TaskSupervisor", :start => {TaskSupervisor, :start_link, ["task_supervisor_args"]}, :restart => {:permanent}, :shutdown => {:infinity}, :type => {:supervisor}}
    _mixed_children_0 = {Phoenix.PubSub, [name: TestApp.PubSub]}
    _mixed_children_1 = %{:id => "legacy_worker", :start => {LegacyWorker, :start_link, [%{}]}, :restart => {:temporary}, :shutdown => {:timeout, 1000}, :type => {:worker}}
    nil
  end
end
