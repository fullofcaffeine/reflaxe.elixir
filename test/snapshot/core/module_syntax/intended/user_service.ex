defmodule UserService do
  def create_user(name, age) do
    "#{(fn -> name end).()} is #{(fn -> Kernel.to_string(age) end).()} years old"
  end
  def process_data(data) do
    data
  end
  def complex_function(arg1, arg2, arg3, _arg4) do
    if (arg3) do
      "#{(fn -> arg1 end).()} #{(fn -> Kernel.to_string(arg2) end).()}"
    end
    "default"
  end
end
