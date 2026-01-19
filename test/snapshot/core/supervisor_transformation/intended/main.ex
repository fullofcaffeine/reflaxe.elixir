defmodule Main do
  def main() do
    _result = ApplicationSupervisor.start_link(%{})
    nil
  end
end
