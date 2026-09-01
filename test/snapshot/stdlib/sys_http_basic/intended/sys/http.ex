defmodule Http do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Http, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Http, key}
    Process.put(static_key, {:set, value})
    value
  end
  def proxy() do
    __haxe_static_get__(:proxy, nil)
  end
  def proxy(value) do
    __haxe_static_put__(:proxy, value)
  end
  def new(url_param) do
    struct = %{:__reflaxe_class__ => Http, :no_shutdown => nil, :cnx_timeout => nil, :response_headers => nil, :url => nil, :response_data => nil, :response_bytes => nil, :on_data => nil, :on_bytes => nil, :on_error => nil, :on_status => nil, :http_base_ref => nil}
    struct = %{struct | no_shutdown: false}
    struct = %{struct | cnx_timeout: 10}
    struct = Map.merge(struct, Map.drop(HttpBase.new(url_param), [:__struct__, :__reflaxe_class__]))
    HttpRuntime.reset_response_headers(struct.http_base_ref)
    struct
  end
  def request(struct, post \\ nil) do
    output = BytesOutput.new()
    is_post = post == true or HttpBaseRuntime.has_request_body(struct.http_base_ref) or HttpRuntime.has_file_transfer(struct.http_base_ref)
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :custom_request, [struct, is_post, output, nil, nil])
    if (not HttpBaseRuntime.failed(struct.http_base_ref)) do
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :success, [struct, apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :get_bytes, [output])])
    end
  end
  def file_transfert(struct, argname, filename, file, size, mime_type \\ "application/octet-stream") do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :file_transfer, [struct, argname, filename, file, size, mime_type])
  end
  def file_transfer(struct, argname, filename, file_input, size, mime_type \\ "application/octet-stream") do
    HttpRuntime.store_file_transfer(struct.http_base_ref, %{param: argname, filename: filename, io: file_input, size: size, mime_type: mime_type})
  end
  def custom_request(struct, post, api, sock \\ nil, method \\ nil) do
    reset_response_state(struct)
    unsupported_message = unsupported_request_message(struct, sock)
    if (not Kernel.is_nil(unsupported_message)) do
      fail(struct, unsupported_message)
    else
      transfer = HttpRuntime.file_transfer(struct.http_base_ref)
      effective_post = post or not Kernel.is_nil(transfer)
      had_explicit_body = HttpBaseRuntime.has_request_body(struct.http_base_ref)
      request_method = if (not Kernel.is_nil(method)), do: method, else: default_method(effective_post)
      payload = request_payload_for(struct, effective_post, transfer, had_explicit_body)
      request_body_data = body_data_for(payload.body)
      request_url = request_url_for(struct, effective_post, payload.body)
      result = HttpRuntime.request(request_method, request_url, header_pairs(struct), request_body_data, payload.content_type, timeout_millis(struct.cnx_timeout))
      handle_result(struct, result, api)
    end
  end
  defp request_payload_for(struct, post, transfer, had_explicit_body) do
    if (Kernel.is_nil(transfer)) do
      body = request_body_for(struct, post)
      %{body: body, content_type: content_type_for(struct, post, body, had_explicit_body)}
    else
      boundary = HttpRuntime.multipart_boundary()
      %{body: multipart_body(struct, transfer, boundary), content_type: "multipart/form-data; boundary=" <> boundary}
    end
  end
  defp handle_result(struct, result, api) do
    if (not HttpRuntime.is_ok(result)) do
      fail(struct, HttpRuntime.error_message(result))
    else
      status = HttpRuntime.status(result)
      store_response_headers(struct, HttpRuntime.headers(result))
      HttpBaseRuntime.call_on_status(struct, status)
      body = Bytes.of_data(HttpRuntime.body(result))
      HttpBaseRuntime.set_response_bytes(struct.http_base_ref, body)
      write_response_body(api, body)
      if (status < 200 or status >= 400), do: fail(struct, "Http Error ##{Reflaxe.Elixir.HaxeFloat.to_string(status)}")
    end
  end
  def get_response_header_values(struct, key) do
    HttpRuntime.response_header_values(struct.http_base_ref, key)
  end
  defp reset_response_state(struct) do
    HttpBaseRuntime.reset_response(struct.http_base_ref)
    HttpRuntime.reset_response_headers(struct.http_base_ref)
  end
  defp fail(struct, message) do
    HttpBaseRuntime.mark_failed(struct.http_base_ref, message)
    HttpBaseRuntime.call_on_error(struct, message)
  end
  defp unsupported_request_message(_struct, sock) do
    if (not Kernel.is_nil(sock)) do
      "sys.Http.customRequest with a caller-supplied Socket is not supported on the Elixir target; use sys.net.Socket directly or let sys.Http use OTP :httpc"
    else
      if (not Kernel.is_nil(Http.proxy())), do: "sys.Http.PROXY is not supported on the Elixir target yet; configure an OTP :httpc profile or an application HTTP client boundary instead", else: nil
    end
  end
  defp multipart_body(struct, transfer, boundary) do
    output = BytesOutput.new()
    _g = 0
    g_value = HttpBaseRuntime.parameter_pairs(struct.http_base_ref)
    Enum.each(g_value, fn parameter ->
      apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "--" <> boundary <> "\r\n", nil])
      apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "Content-Disposition: form-data; name=\"" <> elem(parameter, 0) <> "\"\r\n\r\n", nil])
      apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, elem(parameter, 1) <> "\r\n", nil])
    end)
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "--#{boundary}\r\n", nil])
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "Content-Disposition: form-data; name=\"#{transfer.param}\"; filename=\"#{transfer.filename}\"\r\n", nil])
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "Content-Type: #{transfer.mime_type}\r\n\r\n", nil])
    buffer = Bytes.alloc(4096)
    write_file_bytes(output, transfer.io, transfer.size, buffer)
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_string, [output, "\r\n--#{boundary}--", nil])
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :get_bytes, [output])
  end
  defp request_url_for(struct, post, request_body) do
    if (post or not Kernel.is_nil(request_body)) do
      struct.url
    else
      encoded_params = encode_params(struct)
      if (encoded_params == ""), do: struct.url, else: append_query(struct.url, encoded_params)
    end
  end
  defp request_body_for(struct, post) do
    post_data = HttpBaseRuntime.post_data(struct.http_base_ref)
    if (not Kernel.is_nil(post_data)) do
      body = Bytes.of_string(post_data, {:utf8})
      body
    else
      post_bytes = HttpBaseRuntime.post_bytes(struct.http_base_ref)
      if (not Kernel.is_nil(post_bytes)) do
        post_bytes
      else
        if (post) do
          Bytes.of_string(encode_params(struct), {:utf8})
        else
          nil
        end
      end
    end
  end
  defp content_type_for(struct, post, request_body, had_explicit_body) do
    if (Kernel.is_nil(request_body)) do
      nil
    else
      content_type = header_value(struct, "Content-Type")
      if (not Kernel.is_nil(content_type)) do
        content_type
      else
        if (post and not had_explicit_body), do: "application/x-www-form-urlencoded", else: "application/octet-stream"
      end
    end
  end
  defp header_pairs(struct) do
    HttpBaseRuntime.header_pairs(struct.http_base_ref)
  end
  defp header_value(struct, name) do
    HttpBaseRuntime.header_value(struct.http_base_ref, name)
  end
  defp encode_params(struct) do
    HttpBaseRuntime.encoded_params(struct.http_base_ref)
  end
  defp store_response_headers(struct, pairs) do
    HttpRuntime.store_response_headers(struct.http_base_ref, pairs)
  end
  def get_response_headers(struct) do
    HttpRuntime.response_headers(struct.http_base_ref)
  end
  defp write_response_body(api, body) do
    if (body.length > 0) do
      apply(Map.get(api, :__reflaxe_class__) || Map.get(api, :__struct__), :write_full_bytes, [api, body, 0, body.length])
    end
    apply(Map.get(api, :__reflaxe_class__) || Map.get(api, :__struct__), :close, [api])
  end
  def request_url(url_param) do
    http = Http.new(url_param)
    apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :request, [http, false])
    if (HttpBaseRuntime.failed(http.http_base_ref)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: HttpBaseRuntime.last_error(http.http_base_ref)]
    end
    HttpBase.get_response_data(http)
  end
  defp write_file_bytes(output, input, remaining, buffer) do
    if (remaining <= 0) do
      nil
    else
      requested = if (remaining > buffer.length), do: buffer.length, else: remaining
      read = read_file_chunk(input, buffer, requested)
      if (Kernel.is_nil(read)) do
        nil
      else
        if (read == 0) do
          raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
        end
        apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_full_bytes, [output, buffer, 0, read])
        write_file_bytes(output, input, (remaining - read), buffer)
      end
    end
  end
  defp read_file_chunk(input, buffer, requested) do
    try do
      apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_bytes, [input, buffer, 0, requested])
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Eof -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp default_method(post) do
    if (post), do: "POST", else: "GET"
  end
  defp body_data_for(request_body) do
    if (Kernel.is_nil(request_body)) do
      nil
    else
      apply(Map.get(request_body, :__reflaxe_class__) || Map.get(request_body, :__struct__), :get_data, [request_body])
    end
  end
  defp append_query(base_url, encoded_params) do
    if (StringTools.haxe_index_of(base_url, "?", 0) >= 0) do
      "#{base_url}&#{encoded_params}"
    else
      "#{base_url}?#{encoded_params}"
    end
  end
  defp timeout_millis(seconds) do
    if (Reflaxe.Elixir.HaxeFloat.lt(seconds, 0)), do: 0, else: trunc(Reflaxe.Elixir.HaxeFloat.mul(seconds, 1000))
  end
  def set_header(struct, name, value) do
    HttpBase.set_header(struct, name, value)
  end
  def add_header(struct, header, value) do
    HttpBase.add_header(struct, header, value)
  end
  def set_parameter(struct, name, value) do
    HttpBase.set_parameter(struct, name, value)
  end
  def add_parameter(struct, name, value) do
    HttpBase.add_parameter(struct, name, value)
  end
  def set_post_data(struct, data) do
    HttpBase.set_post_data(struct, data)
  end
  def set_post_bytes(struct, data) do
    HttpBase.set_post_bytes(struct, data)
  end
  def success(struct, data) do
    HttpBase.success(struct, data)
  end
  def on_data(struct, data) do
    HttpBase.on_data(struct, data)
  end
  def on_bytes(struct, data) do
    HttpBase.on_bytes(struct, data)
  end
  def on_error(struct, msg) do
    HttpBase.on_error(struct, msg)
  end
  def on_status(struct, status) do
    HttpBase.on_status(struct, status)
  end
  def get_response_bytes(struct) do
    HttpBase.get_response_bytes(struct)
  end
  def get_response_data(struct) do
    HttpBase.get_response_data(struct)
  end
end
