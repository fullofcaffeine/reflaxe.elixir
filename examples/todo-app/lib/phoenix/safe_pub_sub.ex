defmodule Phoenix.SafePubSub do
  def subscribe_with_converter(topic, topic_converter) do
    pubsub_module = Phoenix.SafePubSub.get_pub_sub_module()
    topic_string = topic_converter.(topic)
    subscribe_result = Phoenix.PubSub.subscribe(pubsub_module, topic_string)
    is_ok = subscribe_result == :ok
    if is_ok do
      {:ok, nil}
    else
      error_reason = 
                case subscribe_result do
                    {:error, reason} -> to_string(reason)
                    _ -> "Unknown subscription error"
                end
      {:error, error_reason}
    end
  end
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    pubsub_module = Phoenix.SafePubSub.get_pub_sub_module()
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
    _this = Date.now()
    payload = Map.put(payload, String.to_atom("timestamp"), DateTime.to_unix(this.datetime, :millisecond))
    payload
  end
  def is_valid_message(msg) do
    msg != nil && Map.has_key?(msg, String.to_atom("type")) && Map.get(msg, String.to_atom("type")) != nil
  end
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"" <> message_type <> "\". Check your message enum definitions."
  end
  def create_malformed_message_error(msg) do
    msg_str = try do
  replacer = nil
  space = nil
  JsonPrinter.print(msg, replacer, space)
rescue
  e ->
    "unparseable message"
end
    "Malformed PubSub message: " <> msg_str <> ". Expected message with \"type\" field."
  end
  def get_pub_sub_module() do
    (

            # Get all loaded applications
            apps = Application.loaded_applications()
            
            # Find the first application that has an endpoint module
            # (This assumes the Phoenix app has at least one endpoint)
            {app_name, endpoint_module} = Enum.find_value(apps, fn {app, _desc, _vsn} ->
                # Get all modules for this application
                case :application.get_key(app, :modules) do
                    {:ok, modules} ->
                        # Find a module that ends with ".Endpoint"
                        endpoint = Enum.find(modules, fn mod ->
                            mod_str = to_string(mod)
                            String.ends_with?(mod_str, ".Endpoint")
                        end)
                        
                        if endpoint, do: {app, endpoint}, else: nil
                    _ ->
                        nil
                end
            end) || {:todo_app, TodoAppWeb.Endpoint}  # Fallback for safety
            
            # Get the pubsub_server from the endpoint configuration
            case Application.get_env(app_name, endpoint_module) do
                nil -> 
                    # Fallback: construct module name from app name
                    # Convert :todo_app to TodoApp.PubSub
                    app_str = app_name
                    |> to_string()
                    |> String.split("_")
                    |> Enum.map(&String.capitalize/1)
                    |> Enum.join("")
                    
                    String.to_atom(app_str <> ".PubSub")
                    
                config when is_list(config) ->
                    # Get pubsub_server from config
                    Keyword.get(config, :pubsub_server) || 
                        # Fallback construction if not configured
                        (app_name
                        |> to_string()
                        |> String.split("_")
                        |> Enum.map(&String.capitalize/1)
                        |> Enum.join("")
                        |> (&(String.to_atom(&1 <> ".PubSub")))
                        .())
            end
        
)
  end
end