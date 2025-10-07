defmodule Main do
  def main() do
    test_topic_conversion()
    test_message_patterns()
    test_complex_names()
  end
  defp test_topic_conversion() do
    topic = :todo_updates
    topic_string = case (topic) do
      :todo_updates ->
        "todo:updates"
      :user_activity ->
        "user:activity"
      :system_notifications ->
        "system:notifications"
      :http_server_start ->
        "http:server:start"
      :io_manager_ready ->
        "io:manager:ready"
    end
    Log.trace("Topic string: #{topic_string}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testTopicConversion"})
  end
  defp test_message_patterns() do
    message = {:todo_created, %{:id => 1, :title => "Test"}}
    result = case (message) do
      {:todo_created, todo} ->
        "Created todo: #{inspect(todo)}"
      {:todo_updated, todo} ->
        "Updated todo: #{inspect(todo)}"
      {:todo_deleted, id} ->
        "Deleted todo: #{id}"
      {:bulk_update, action} ->
        "Bulk action: #{action}"
      {:user_online, user_id} ->
        "User #{userId} is online"
      {:user_offline, user_id} ->
        "User #{userId} is offline"
      {:system_alert, level, msg} ->
        "Alert [#{level}]: #{msg}"
    end
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testMessagePatterns"})
  end
  defp test_complex_names() do
    request = :xml_http_request
    description = case (request) do
      :xml_http_request ->
        "XML HTTP Request"
      :jsonapi_response ->
        "JSON API Response"
      :otp_supervisor ->
        "OTP Supervisor"
      :https_connection ->
        "HTTPS Connection"
      :web_socket_io_manager ->
        "WebSocket IO Manager"
    end
    Log.trace(description, %{:file_name => "Main.hx", :line_number => 108, :class_name => "Main", :method_name => "testComplexNames"})
  end
  defp get_topic_atom(topic) do
    __elixir_switch_result_1 = case (topic) do
      :todo_updates ->
        "todo_updates_atom"
      :user_activity ->
        "user_activity_atom"
      :system_notifications ->
        "system_notifications_atom"
      :http_server_start ->
        "http_server_start_atom"
      :io_manager_ready ->
        "io_manager_ready_atom"
    end
    __elixir_switch_result_1
  end
end