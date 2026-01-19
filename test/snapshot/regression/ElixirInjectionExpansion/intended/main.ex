defmodule Main do
  def main() do
    _current_time = DateTime.utc_now()
    name = "Alice"
    _greeting = "Hello, #{name}!"
    x = 10
    y = 20
    _result = x + y
    date_str = "2025-01-29T12:00:00Z"
    parsed_date = 
            case DateTime.from_iso8601(date_str) do
                {:ok, dt, _} -> dt
                _ -> DateTime.utc_now()
            end
        
    nil
    parsed_date
  end
end
