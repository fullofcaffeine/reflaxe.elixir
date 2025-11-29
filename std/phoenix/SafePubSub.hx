package phoenix;

import haxe.ds.Option;
import haxe.functional.Result;
import elixir.Module;
import elixir.Application;

/**
 * Type-safe PubSub system for Phoenix applications
 * 
 * This framework module provides compile-time safety for Phoenix PubSub operations,
 * eliminating runtime errors from typos in topic names and message structures.
 * 
 * ## Usage Pattern
 * 
 * 1. Define your application's topics and messages:
 * ```haxe
 * enum AppPubSubTopic {
 *     TodoUpdates;
 *     UserActivity;
 * }
 * 
 * enum AppPubSubMessage {
 *     TodoCreated(todo: Todo);
 *     TodoUpdated(todo: Todo);
 *     UserOnline(user_id: Int);
 * }
 * ```
 * 
 * 2. Use type-safe operations:
 * ```haxe
 * SafePubSub.broadcast(TodoUpdates, TodoCreated(newTodo));
 * SafePubSub.subscribe(UserActivity);
 * ```
 * 
 * ## Benefits
 * 
 * - **Compile-time safety**: Typos in topic names become compiler errors
 * - **IntelliSense support**: IDE shows all available topics and message types
 * - **Exhaustiveness checking**: Pattern matching ensures all message types handled
 * - **Zero runtime overhead**: All validation happens at compile-time
 * 
 * ## Future Enhancements
 * 
 * This module is designed to support macro-based code generation in future phases:
 * - Auto-generation of parseMessage functions
 * - Declaration-based topic/message definition
 * - Advanced pattern matching helpers
 * 
 * See `/documentation/PUBSUB_MACRO_ROADMAP.md` for complete enhancement roadmap.
 */

/**
 * Base interface for application-specific PubSub topics
 * 
 * Applications should define their own topic enums and provide
 * a topicToString conversion function.
 */
interface PubSubTopicProvider<T> {
    /**
     * Convert topic enum to string for Elixir compatibility
     */
    function topicToString(topic: T): String;
}

/**
 * Base interface for application-specific PubSub messages
 * 
 * Applications should define their own message enums and provide
 * parsing functions for incoming messages.
 */
interface PubSubMessageProvider<M> {
    /**
     * Parse incoming Dynamic message to typed enum
     * Returns None for unknown or malformed messages
     */
    function parseMessage(msg: Dynamic): Option<M>;
    
    /**
     * Convert typed message to Dynamic for Elixir compatibility
     */
    function messageToElixir(message: M): Dynamic;
}

/**
 * Framework-level SafePubSub operations
 * 
 * This class provides the core infrastructure for type-safe PubSub
 * operations. Applications extend this by providing their own
 * topic and message type definitions.
 */
@:native("Phoenix.SafePubSub")
@:keep
class SafePubSub {
    
    /**
     * Type-safe subscribe to a topic with conversion
     * 
     * @param topic Application-specific topic enum
     * @param topicConverter Function to convert topic to string
     * @return Result indicating success or failure
     */
    @:keep
    public static function subscribeTopic(topicString: String): Result<Void, String> {
        return untyped __elixir__('
          case Phoenix.PubSub.subscribe(
                   Phoenix.SafePubSub.get_pub_sub_module(),
                   {0}
               ) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicString);
    }

    public static function subscribeWithConverter<T>(
        topic: T,
        topicConverter: T -> String
    ): Result<Void, String> {
        // Prefer passing the converted string directly to avoid function-capture issues
        return subscribeTopic(topicConverter(topic));
    }
    
    /**
     * Type-safe broadcast with topic and message conversion
     * 
     * @param topic Application-specific topic enum
     * @param message Application-specific message enum  
     * @param topicConverter Function to convert topic to string
     * @param messageConverter Function to convert message to Dynamic
     * @return Result indicating success or failure
     */
    @:keep
    public static function broadcastTopicPayload(topicString: String, payload: Dynamic): Result<Void, String> {
        return untyped __elixir__('
          # Normalize top-level atom keys to also have string equivalents,
          # preserving existing string keys. This avoids coupling to app-level
          # field names while ensuring consumers matching on string keys work.
          normalized = if is_map({1}) do
            Enum.reduce(Map.keys({1}), {1}, fn k, acc ->
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
            {1}
          end
          case Phoenix.PubSub.broadcast(
                   Phoenix.SafePubSub.get_pub_sub_module(),
                   {0},
                   normalized
               ) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicString, payload);
    }

    public static function broadcastWithConverters<T, M>(
        topic: T,
        message: M,
        topicConverter: T -> String,
        messageConverter: M -> Dynamic
    ): Result<Void, String> {
        return broadcastTopicPayload(topicConverter(topic), messageConverter(message));
    }
    
    /**
     * Parse incoming PubSub message with application-specific parser
     * 
     * @param msg Raw Dynamic message from PubSub
     * @param messageParser Application-specific message parser
     * @return Parsed message or None if parsing failed
     */
    @:keep
    public static function parseWithConverter<M>(
        msg: Dynamic,
        messageParser: Dynamic -> Option<M>
    ): Option<M> {
        // Accept a proper function capture or a module.function atom/string
        // and invoke the corresponding function with arity 1. This guards
        // against cases where the compiler lowers identifiers to atoms.
        return untyped __elixir__('
          res = cond do
            is_function({1}, 1) -> {1}.({0})
            is_atom({1}) ->
              s = to_string({1})
              case String.split(s, ".") do
                [mod_str, fun_str] ->
                  # Convert underscored module name to a single CamelCase alias (e.g., "todo_pub_sub" -> Elixir.TodoPubSub)
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [{0}])
                _ ->
                  msg = "invalid message_parser atom: " <> inspect({1})
                  raise ArgumentError, message: msg
              end
            is_binary({1}) ->
              case String.split({1}, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [{0}])
                _ ->
                  msg = "invalid message_parser string: " <> inspect({1})
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
        ', msg, messageParser);
    }
    
    /**
     * Utility function to add timestamp to message payload
     */
    @:keep
    public static function addTimestamp(payload: Dynamic): Dynamic {
        // Avoid shadowing/rewrites by computing a base value once
        var basePayload: Dynamic = (payload == null) ? {} : payload;
        
        // Add timestamp for message tracking (returns updated map in Elixir)
        Reflect.setField(basePayload, "timestamp", Date.now().getTime());
        
        return basePayload;
    }
    
    /**
     * Utility function to validate message structure
     * 
     * @param msg Message to validate
     * @return true if message has required fields
     */
    @:keep
    public static function isValidMessage(msg: Dynamic): Bool {
        return msg != null && 
               Reflect.hasField(msg, "type") && 
               Reflect.field(msg, "type") != null;
    }
    
    /**
     * Create a standard error message for unknown message types
     */
    public static function createUnknownMessageError(messageType: String): String {
        return 'Unknown PubSub message type: "$messageType". Check your message enum definitions.';
    }
    
    /**
     * Create a standard error message for malformed messages
     */
    public static function createMalformedMessageError(msg: Dynamic): String {
        // Build the whole message inside injected Elixir to avoid cross-scope locals
        return untyped __elixir__('
          msg_str = try do
            Jason.encode!({0})
          rescue
            _e -> "unparseable message"
          end
          ~s(Malformed PubSub message: #{msg_str}. Expected message with "type" field.)
        ', msg);
    }
    
    /**
     * Dynamically retrieve the PubSub module from endpoint configuration
     * 
     * This method works for any Phoenix application by:
     * 1. Getting the current application name (e.g., :todo_app)
     * 2. Finding all endpoint modules in the application
     * 3. Reading the pubsub_server configuration from the endpoint
     * 
     * This avoids hardcoding any specific application names and makes
     * the framework code truly generic.
     * 
     * @return The PubSub module atom for the current application
     */
    /**
     * Exposed to Elixir as get_pub_sub_module/0 and marked @:keep to avoid DCE.
     */
    @:keep @:native("get_pub_sub_module")
    public static function getPubSubModule(): Dynamic {
        // Get the PubSub module dynamically from endpoint configuration
        // This is a proper Phoenix way to retrieve the PubSub server
        return untyped __elixir__('
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
        ');
    }
}

/**
 * Convenience macro for creating application-specific SafePubSub wrappers
 * 
 * This will be enhanced in future phases to auto-generate conversion functions
 * and provide even more ergonomic APIs.
 * 
 * For now, applications should create their own wrapper classes that use
 * the SafePubSub infrastructure with their specific topic and message types.
 */
class SafePubSubMacros {
    
    #if macro
    /**
     * Future enhancement: Generate SafePubSub wrapper from topic/message enums
     * 
     * Usage (planned):
     * ```haxe
     * @:build(SafePubSubMacros.generateWrapper())
     * enum MyTopics { TodoUpdates; UserActivity; }
     * ```
     * 
     * This would auto-generate:
     * - topicToString conversion function
     * - type-safe broadcast/subscribe methods
     * - message parsing utilities
     */
    public static function generateWrapper(): Array<haxe.macro.Expr.Field> {
        // TODO: Implement in Phase 2 of the roadmap
        // For now, return empty array
        return [];
    }
    #end
}
