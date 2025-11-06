defmodule Elixir.Otp.SupervisorStrategy do
  def one_for_one() do
    {:one_for_one}
  end
  def one_for_all() do
    {:one_for_all}
  end
  def rest_for_one() do
    {:rest_for_one}
  end
  def simple_one_for_one() do
    {:simple_one_for_one}
  end
end
