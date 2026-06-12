defmodule HttpBase do
  def new(url_param) do
    struct = %{:__reflaxe_class__ => HttpBase, :url => nil, :response_data => nil, :response_bytes => nil, :on_data => nil, :on_bytes => nil, :on_error => nil, :on_status => nil, :http_base_ref => nil}
    struct = %{struct | url: url_param}
    struct = %{struct | http_base_ref: HttpBaseRuntime.create()}
    struct = %{struct | on_data: &default_on_data/1}
    struct = %{struct | on_bytes: &default_on_bytes/1}
    struct = %{struct | on_error: &default_on_error/1}
    struct = %{struct | on_status: &default_on_status/1}
    struct
  end
  def set_header(struct, name, value) do
    HttpBaseRuntime.set_header(struct.http_base_ref, name, value)
  end
  def add_header(struct, header, value) do
    HttpBaseRuntime.add_header(struct.http_base_ref, header, value)
  end
  def set_parameter(struct, name, value) do
    HttpBaseRuntime.set_parameter(struct.http_base_ref, name, value)
  end
  def add_parameter(struct, name, value) do
    HttpBaseRuntime.add_parameter(struct.http_base_ref, name, value)
  end
  def set_post_data(struct, data) do
    HttpBaseRuntime.set_post_data(struct.http_base_ref, data)
  end
  def set_post_bytes(struct, data) do
    HttpBaseRuntime.set_post_bytes(struct.http_base_ref, data)
  end
  def request(_struct, _post) do
    raise Reflaxe.Elixir.HaxeThrow, [value: NotImplementedException.new(nil, nil, %{:file_name => "../../../../std/haxe/http/HttpBase.hx", :line_number => 74, :class_name => "haxe.http.HttpBase", :method_name => "request"})]
  end
  def success(struct, data) do
    _ = HttpBaseRuntime.set_response_bytes(struct.http_base_ref, data)
    _ = HttpBaseRuntime.call_on_data(struct, get_response_data(struct))
    _ = HttpBaseRuntime.call_on_bytes(struct, data)
  end
  def on_data(struct, data) do
    HttpBaseRuntime.call_on_data(struct, data)
  end
  def on_bytes(struct, data) do
    HttpBaseRuntime.call_on_bytes(struct, data)
  end
  def on_error(struct, msg) do
    HttpBaseRuntime.call_on_error(struct, msg)
  end
  def on_status(struct, status) do
    HttpBaseRuntime.call_on_status(struct, status)
  end
  def get_response_bytes(struct) do
    HttpBaseRuntime.response_bytes(struct.http_base_ref)
  end
  def get_response_data(struct) do
    bytes = get_response_bytes(struct)
    if (Kernel.is_nil(bytes)) do
      nil
    else
      apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get_string, [bytes, 0, bytes.length, {:utf8}])
    end
  end
  defp default_on_data(_data) do
    
  end
  defp default_on_bytes(_data) do
    
  end
  defp default_on_error(_msg) do
    
  end
  defp default_on_status(_status) do
    
  end
end
