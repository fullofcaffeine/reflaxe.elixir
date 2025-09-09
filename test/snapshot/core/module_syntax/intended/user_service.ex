defmodule UserService do
  def create_user(name, age) do
    name <> " is " <> Kernel.to_string(age) <> " years old"
  end
  defp validate_age(age) do
    age >= 0 && age <= 150
  end
  def process_data(data) do
    data
  end
  def complex_function(arg1, arg2, arg3, _arg4) do
    if arg3 do
      arg1 <> " " <> Kernel.to_string(arg2)
    end
    "default"
  end
end