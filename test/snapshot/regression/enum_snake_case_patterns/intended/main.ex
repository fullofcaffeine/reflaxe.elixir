defmodule Main do
  def main() do
    test_topic_conversion()
    test_message_patterns()
    test_complex_names()
  end
  defp test_topic_conversion() do
    topic = {:todo_updates}
    _topic_string = (case topic do
      {:todo_updates} -> "todo:updates"
      {:user_activity} -> "user:activity"
      {:system_notifications} -> "system:notifications"
      {:http_server_start} -> "http:server:start"
      {:io_manager_ready} -> "io:manager:ready"
    end)
    nil
  end
  defp test_message_patterns() do
    message = {:todo_created, %{id: 1, title: "Test"}}
    _result = (case message do
      {:todo_created, todo} -> "Created todo: #{Reflaxe.Elixir.HaxeFloat.to_string(todo)}"
      {:todo_updated, todo} -> "Updated todo: #{Reflaxe.Elixir.HaxeFloat.to_string(todo)}"
      {:todo_deleted, id} -> "Deleted todo: #{Reflaxe.Elixir.HaxeFloat.to_string(id)}"
      {:bulk_update, action} -> "Bulk action: #{action}"
      {:user_online, user_id} -> "User #{Reflaxe.Elixir.HaxeFloat.to_string(user_id)} is online"
      {:user_offline, user_id} -> "User #{Reflaxe.Elixir.HaxeFloat.to_string(user_id)} is offline"
      {:system_alert, _message, level} -> "Alert [#{level}]: #{msg}"
    end)
    nil
  end
  defp test_complex_names() do
    request = {:xml_http_request}
    _description = (case request do
      {:xml_http_request} -> "XML HTTP Request"
      {:jsonapi_response} -> "JSON API Response"
      {:otp_supervisor} -> "OTP Supervisor"
      {:https_connection} -> "HTTPS Connection"
      {:web_socket_io_manager} -> "WebSocket IO Manager"
    end)
    nil
  end
end
