defmodule Main do
  def main() do
    Log.__get_trace().("Hello external bootstrap!", nil)
  end
end
