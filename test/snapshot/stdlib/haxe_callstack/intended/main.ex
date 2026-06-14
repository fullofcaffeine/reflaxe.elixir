defmodule Main do
  def main() do
    current = CallStack_Impl_.call_stack()
    copied = current
    _exception = CallStack_Impl_.exception_stack(true)
    _shortened = CallStack_Impl_.subtract(current, copied)
    _printable = CallStack_Impl_.to_string(current)
    nil
  end
end
