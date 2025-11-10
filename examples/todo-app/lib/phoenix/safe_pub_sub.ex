defmodule Phoenix.SafePubSub do
  def broadcast_topic_payload(topic_string, payload) do
    (

          # Normalize top-level atom keys to also have string equivalents,
          # preserving existing string keys. This avoids coupling to app-level
          # field names while ensuring consumers matching on string keys work.
          normalized = if is_map(payload) do
            Enum.reduce(Map.keys(payload), payload, fn k, acc ->
              cond do
                is_atom(k) ->
                  sk = Atom.to_string(k)
                  if Map.has_key?(acc, sk) do
                    acc
                  else
                    Map.put(acc, sk, Map.get(acc, k))
                  end
                true -> acc
              end
            end)
          else
            payload
          end
          case Phoenix.PubSub.broadcast(
                   Phoenix.SafePubSub.get_pub_sub_module(),
                   topic_string,
                   normalized
               ) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        
)
  end
  def parse_with_converter(msg, message_parser) do
    (

          res = cond do
            is_function(message_parser, 1) -> message_parser.(msg)
            is_atom(message_parser) ->
              s = to_string(message_parser)
              case String.split(s, ".") do
                [mod_str, fun_str] ->
                  # Convert underscored module name to a single CamelCase alias (e.g., "todo_pub_sub" -> Elixir.TodoPubSub)
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [msg])
                _ ->
                  msg = "invalid message_parser atom: " <> inspect(message_parser)
                  raise ArgumentError, message: msg
              end
            is_binary(message_parser) ->
              case String.split(message_parser, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [msg])
                _ ->
                  msg = "invalid message_parser string: " <> inspect(message_parser)
                  raise ArgumentError, message: msg
              end
            true ->
              raise ArgumentError, message: "invalid message_parser: expected function/1 or module.function string"
          end
          # Normalize nested Option shapes defensively
          case res do
            {:some, {:some, v}} -> {:some, v}
            {:some, :none} -> :none
            other -> other
          end
        
)
  end
  def add_timestamp(payload) do
    base_payload = if (Kernel.is_nil(payload)), do: %{}, else: payload
    Map.put(base_payload, "timestamp", DateTime.to_unix(DateTime.utc_now(), :millisecond))
    base_payload
  end
  def is_valid_message(msg) do
    not Kernel.is_nil(msg) and Map.has_key?(msg, "type") and not Kernel.is_nil(Map.get(msg, "type"))
  end
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"#{(fn -> message_type end).()}\". Check your message enum definitions."
  end
  def create_malformed_message_error(msg) do
    (

          msg_str = try do
            Jason.encode!(msg)
          rescue
            _e -> "unparseable message"
          end
          ~s(Malformed PubSub message: #{(fn -> msg_str end).()}. Expected message with "type" field.)
        
)
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
                IO.puts("[SafePubSub] app=#{(fn -> inspect(app_name) end).()} endpoint=#{(fn -> inspect(endpoint_module) end).()} pubsub=#{(fn -> inspect(pubsub_mod) end).()}")
            end
            pubsub_mod
        
)
  end
end
