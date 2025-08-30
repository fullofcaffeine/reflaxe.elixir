defmodule SupervisorStrategy do
  def one_for_one() do
    {:OneForOne}
  end
  def one_for_all() do
    {:OneForAll}
  end
  def rest_for_one() do
    {:RestForOne}
  end
  def simple_one_for_one() do
    {:SimpleOneForOne}
  end
end