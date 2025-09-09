defmodule Phoenix.SafePubSub do
  def subscribe_with_converter(topic, topic_converter) do
    pubsub_module = get_pub_sub_module()
    topic_string = topic_converter.(topic)
    subscribe_result = Phoenix.PubSub.subscribe(pubsub_module, topic_string)
    is_ok = subscribe_result == :ok
    if is_ok, do: {:ok, nil}, else: {:error, (
                case subscribe_result do
                    {:error, reason} -> to_string(reason)
                    _ -> "Unknown subscription error"
                end)}
  end
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    pubsub_module = get_pub_sub_module()
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(pubsub_module, topic_string, message_payload)
  end
  def parse_with_converter(msg, message_parser) do
    message_parser.(msg)
  end
  def add_timestamp(payload) do
    if (payload == nil) do
      payload = %{}
    end
    payload = Map.put(payload, String.to_atom("timestamp"), Date_Impl_.get_time(DateTime.utc_now()))
    payload
  end
  def is_valid_message(msg) do
    msg != nil && Map.has_key?(msg, String.to_atom("type")) && Map.get(msg, String.to_atom("type")) != nil
  end
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"" <> message_type <> "\". Check your message enum definitions."
  end
  def create_malformed_message_error(msg) do
    "Malformed PubSub message: " <> (try do
  replacer = nil
  space = nil
  JsonPrinter.print(msg, replacer, space)
rescue
  e ->
    "unparseable message"
end) <> ". Expected message with \"type\" field."
  end
  def get_pub_sub_module() do
    (

            debug? = System.get_env("SAFE_PUBSUB_DEBUG") in ["1", "true", "TRUE"]
            
            # Get all loaded applications
            apps = Application.loaded_applications()
            
            # Find the first application that has an endpoint module
            {app_name, endpoint_module} = Enum.find_value(apps, fn {app, _desc, _vsn} ->
                case :application.get_key(app, :modules) do
                    {:ok, modules} ->
                        endpoint = Enum.find(modules, fn mod ->
                            mod_str = to_string(mod)
                            String.ends_with?(mod_str, ".Endpoint")
                        end)
                        if endpoint, do: {app, endpoint}, else: nil
                    _ -> nil
                end
            end) || {:todo_app, TodoAppWeb.Endpoint}
            
            pubsub_mod = case Application.get_env(app_name, endpoint_module) do
                nil -> 
                    # Fallback: construct proper module alias from app name
                    app_mod = app_name
                    |> to_string()
                    |> String.split("_")
                    |> Enum.map(&String.capitalize/1)
                    |> Module.concat()
                    Module.concat(app_mod, :PubSub)
                config when is_list(config) ->
                    Keyword.get(config, :pubsub_server) || 
                        (app_name
                        |> to_string()
                        |> String.split("_")
                        |> Enum.map(&String.capitalize/1)
                        |> Module.concat()
                        |> (&Module.concat(&1, :PubSub)).())
            end
            if debug? do
                IO.puts("[SafePubSub] app=#{inspect(app_name)} endpoint=#{inspect(endpoint_module)} pubsub=#{inspect(pubsub_mod)}")
            end
            pubsub_mod
        
)
  end
end