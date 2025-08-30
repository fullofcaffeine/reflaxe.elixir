defmodule ChildSpecFormat do
  def module_ref(arg0) do
    {:ModuleRef, arg0}
  end
  def module_with_args(arg0, arg1) do
    {:ModuleWithArgs, arg0, arg1}
  end
  def module_with_config(arg0, arg1) do
    {:ModuleWithConfig, arg0, arg1}
  end
  def full_spec(arg0) do
    {:FullSpec, arg0}
  end
end