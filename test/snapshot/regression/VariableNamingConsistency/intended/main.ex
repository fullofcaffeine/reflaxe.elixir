defmodule Main do
  def main() do
    conditional_var = "test"
    if (not Kernel.is_nil(conditional_var)), do: nil
    nil
  end
end
