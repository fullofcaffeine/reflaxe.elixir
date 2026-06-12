defmodule Sys.Thread.Tls do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.Tls, :ref => nil, :value => nil}
    struct = %{struct | ref: make_ref()}
    struct
  end
  def get_value(struct) do
    Process.get({:reflaxe_sys_thread_tls, struct.ref})
  end
  def set_value(struct, value_param) do
    Process.put({:reflaxe_sys_thread_tls, struct.ref}, value_param)
    value_param
  end
end
