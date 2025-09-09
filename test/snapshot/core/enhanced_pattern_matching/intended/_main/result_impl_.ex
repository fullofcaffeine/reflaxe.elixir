defmodule Result_Impl_ do
  def _new(result) do
    this1 = nil
    this1 = result
    this1
  end
  def success(value) do
    result = {:Success, value}
    this1 = nil
    this1 = result
    this1
  end
  def error(error, context) do
    result = {:Error, error, context}
    this1 = nil
    this1 = result
    this1
  end
end