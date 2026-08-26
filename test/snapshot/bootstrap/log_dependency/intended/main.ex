defmodule Main do
  def main() do
    Log.__get_trace().("Hello from bootstrap!", nil)
  end
end
