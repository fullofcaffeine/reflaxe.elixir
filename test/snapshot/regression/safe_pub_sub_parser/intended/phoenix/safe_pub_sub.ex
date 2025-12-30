defmodule Phoenix.SafePubSub do
  def subscribe_topic(topic_string) do
    pubsub_mod = get_pub_sub_module()
    if (Kernel.is_nil(pubsub_mod)) do
      {:error, "SafePubSub could not determine the PubSub server module (no Phoenix Endpoint detected)."}
    else
      
          case Phoenix.PubSub.subscribe(pubsub_mod, topic_string) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        
    end
  end
  def subscribe_with_converter(topic, topic_converter) do
    subscribe_topic(topic_converter.(topic))
  end
  def broadcast_topic_payload(topic_string, payload) do
    pubsub_mod = get_pub_sub_module()
    if (Kernel.is_nil(pubsub_mod)) do
      {:error, "SafePubSub could not determine the PubSub server module (no Phoenix Endpoint detected)."}
    else
      
          normalized = if is_map(payload) do
            Enum.reduce(Map.keys(payload), payload, fn k, acc ->
              cond do
                is_atom(k) ->
                  sk = Atom.to_string(k)
                  if Map.has_key?(acc, sk), do: acc, else: Map.put(acc, sk, Map.get(acc, k))
                true -> acc
              end
            end)
          else
            payload
          end
          case Phoenix.PubSub.broadcast(pubsub_mod, topic_string, normalized) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        
    end
  end
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    broadcast_topic_payload(topic_converter.(topic), message_converter.(message))
  end
  def parse_with_converter(msg, message_parser) do
    
          res = cond do
            is_function(message_parser, 1) -> message_parser.(msg)
            is_atom(message_parser) ->
              s = to_string(message_parser)
              case String.split(s, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [msg])
                _ -> raise ArgumentError, message: "invalid message_parser atom: " <> inspect(message_parser)
              end
            is_binary(message_parser) ->
              case String.split(message_parser, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [msg])
                _ -> raise ArgumentError, message: "invalid message_parser string: " <> inspect(message_parser)
              end
            true -> raise ArgumentError, message: "invalid message_parser: expected function/1 or module.function string"
          end
          case res do
            {:some, {:some, v}} -> {:some, v}
            {:some, :none} -> :none
            other -> other
          end
        
  end
  def add_timestamp(payload) do
    Map.put(payload || %{}, :timestamp, System.system_time(:millisecond))
  end
  def is_valid_message(msg) do
    not Kernel.is_nil(msg) and Map.has_key?(msg, "type") and not Kernel.is_nil(Map.get(msg, "type"))
  end
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"#{message_type}\". Check your message enum definitions."
  end
  def create_malformed_message_error(msg) do
    
          msg_str = try do
            Jason.encode!(msg)
          rescue
            _e -> "unparseable message"
          end
          ~s(Malformed PubSub message: #{msg_str}. Expected message with "type" field.)
        
  end
  def get_pub_sub_module() do
    
          key = {__MODULE__, :cached_pubsub_module}
          case :persistent_term.get(key, :undefined) do
            :undefined ->
              pubsub_mod =
                (fn ->
                  apps = Application.loaded_applications()
                  Enum.find_value(apps, fn {app, _desc, _vsn} ->
                    case :application.get_key(app, :modules) do
                      {:ok, modules} ->
                        endpoint = Enum.find(modules, fn mod ->
                          mod_str = to_string(mod)
                          String.ends_with?(mod_str, ".Endpoint")
                        end)
                        if endpoint do
                          app
                          |> to_string()
                          |> String.split("_")
                          |> Enum.map(&String.capitalize/1)
                          |> Module.concat()
                          |> (&Module.concat(&1, :PubSub)).()
                        else
                          nil
                        end
                      _ -> nil
                    end
                  end)
                end).()

              if is_nil(pubsub_mod) do
                nil
              else
                :persistent_term.put(key, pubsub_mod)
                pubsub_mod
              end

            cached ->
              cached
          end
        
  end
end
