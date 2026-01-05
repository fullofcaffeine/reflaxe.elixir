defmodule Main do
  def main() do
    user_id = 123
    username = "john_doe"
    _api_response_data_value_0_id = user_id
    _api_response_data_value_0_name = username
    _callback = fn _, code -> code == 200 end
    _handler = fn -> nil end
    _api_response_metadata_timestamp = DateTime.to_iso8601(DateTime.utc_now())
    nil
  end
end
