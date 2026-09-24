defmodule Main do
  def main() do
    test_topic_conversion()
    assert_text(test_message_patterns({:todo_created, "new"}), "Created todo: new")
    assert_text(test_message_patterns({:todo_updated, "changed"}), "Updated todo: changed")
    assert_text(test_message_patterns({:todo_deleted, 7}), "Deleted todo: 7")
    assert_text(test_message_patterns({:bulk_update, "refresh"}), "Bulk action: refresh")
    assert_text(test_message_patterns({:user_online, 8}), "User 8 is online")
    assert_text(test_message_patterns({:user_offline, 9}), "User 9 is offline")
    assert_text(test_message_patterns({:system_alert, "check", "info"}), "Alert [info]: check")
    test_complex_names()
  end
  defp test_topic_conversion() do
    _topic_string = (case {:todo_updates} do
      {:todo_updates} -> "todo:updates"
      {:user_activity} -> "user:activity"
      {:system_notifications} -> "system:notifications"
      {:http_server_start} -> "http:server:start"
      {:io_manager_ready} -> "io:manager:ready"
    end)
    nil
  end
  defp test_message_patterns(message) do
    (case message do
      {:todo_created, todo} -> "Created todo: #{Reflaxe.Elixir.HaxeFloat.to_string(todo)}"
      {:todo_updated, todo} -> "Updated todo: #{Reflaxe.Elixir.HaxeFloat.to_string(todo)}"
      {:todo_deleted, id} -> "Deleted todo: #{Reflaxe.Elixir.HaxeFloat.to_string(id)}"
      {:bulk_update, action} -> "Bulk action: #{action}"
      {:user_online, user_id} -> "User #{Reflaxe.Elixir.HaxeFloat.to_string(user_id)} is online"
      {:user_offline, user_id} -> "User #{Reflaxe.Elixir.HaxeFloat.to_string(user_id)} is offline"
      {:system_alert, message, level} ->
        msg = message
        "Alert [#{level}]: #{msg}"
    end)
  end
  defp assert_text(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected " <> expected <> ", got " <> actual]
    end
  end
  defp test_complex_names() do
    _description = (case {:xml_http_request} do
      {:xml_http_request} -> "XML HTTP Request"
      {:jsonapi_response} -> "JSON API Response"
      {:otp_supervisor} -> "OTP Supervisor"
      {:https_connection} -> "HTTPS Connection"
      {:web_socket_io_manager} -> "WebSocket IO Manager"
    end)
    nil
  end
end
