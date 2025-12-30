defmodule UserService do
  def create_user(name, age) do
    "#{name} is #{Kernel.to_string(age)} years old"
  end
  def process_data(data) do
    data
  end
  def complex_function(arg1, arg2, arg3, _) do
    if (arg3) do
      "#{arg1} #{Kernel.to_string(arg2)}"
    else
      "default"
    end
  end
end
