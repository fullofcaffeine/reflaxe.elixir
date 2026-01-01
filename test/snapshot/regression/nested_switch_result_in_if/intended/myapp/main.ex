defmodule Main do
  def main() do
    _ = NestedSwitchResultInIf.run(true)
    _ = NestedSwitchResultInIf.run_inner_only(1)
  end
end
