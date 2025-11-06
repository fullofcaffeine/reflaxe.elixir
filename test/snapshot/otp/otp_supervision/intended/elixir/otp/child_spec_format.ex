defmodule Elixir.Otp.ChildSpecFormat do
  def module_ref(arg0) do
    {:module_ref, arg0}
  end
  def module_with_args(arg0, arg1) do
    {:module_with_args, arg0, arg1}
  end
  def module_with_config(arg0, arg1) do
    {:module_with_config, arg0, arg1}
  end
  def full_spec(arg0) do
    {:full_spec, arg0}
  end
end
