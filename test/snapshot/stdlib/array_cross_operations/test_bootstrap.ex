defmodule TestBootstrap do
  def main() do
    IO.puts("Bootstrap code executed successfully!")
    IO.puts("Testing modulo with rem function: rem(5, 2) = #{rem(5, 2)}")
    IO.puts("Testing private function calls...")
    test_private()
  end
  
  defp test_private() do
    IO.puts("Private function called without module prefix - SUCCESS!")
  end
end

# Bootstrap code that should execute automatically
TestBootstrap.main()