defmodule Main do
  def main() do
    Log.__get_trace().("Hello inline deterministic!", nil)
  end
end
