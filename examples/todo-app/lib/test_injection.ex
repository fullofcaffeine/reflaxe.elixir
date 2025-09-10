defmodule TestInjection do
  def test_direct_injection() do
    "Hello from Elixir"
  end
  def test_variable_substitution() do
    x * 2
  end
  def test_supervisor_call() do
    Supervisor.start_link(children, [strategy: :one_for_one, name: TestSupervisor])
  end
  def test_complex_injection() do
    module = "TestModule"
    func = "test_func"
    args = [1, 2, 3]
    module.func(args)
  end
end