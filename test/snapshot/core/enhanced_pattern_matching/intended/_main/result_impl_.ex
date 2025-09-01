defmodule Result_Impl_ do
  def _new(result) do
    this_1 = nil
    this_1 = result
    this_1
  end
  def success(value) do
    result = {:Success, value}
    this_1 = nil
    this_1 = result
    this_1
  end
  def error(error, context) do
    result = {:Error, error, context}
    this_1 = nil
    this_1 = result
    this_1
  end
end