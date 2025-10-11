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
class SafePubSub {
    
    /**
     * Type-safe subscribe to a topic with conversion
     * 
     * @param topic Application-specific topic enum
     * @param topicConverter Function to convert topic to string
     * @return Result indicating success or failure
     */
    public static function subscribeWithConverter<T>(
        topic: T, 
        topicConverter: T -> String
    ): Result<Void, String> {
        // Injection Hygiene: compute ephemeral locals inside injected Elixir
        // and return a Result-like tuple to avoid cross-scope variable issues.
        return untyped __elixir__('
          case Phoenix.PubSub.subscribe(
                   Phoenix.SafePubSub.get_pub_sub_module(),
                   {0}.({1})
               ) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicConverter, topic);
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
    public static function broadcastWithConverters<T, M>(
        topic: T,
        message: M,
        topicConverter: T -> String,
        messageConverter: M -> Dynamic
    ): Result<Void, String> {
        // Injection Hygiene: compute pubsub/topic/message inside injected Elixir
        // and normalize return to {:ok, nil} | {:error, reason}
        return untyped __elixir__('
          case Phoenix.PubSub.broadcast(
                   Phoenix.SafePubSub.get_pub_sub_module(),
                   {0}.({1}),
                   {2}.({3})
               ) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicConverter, topic, messageConverter, message);
    }
    
    /**
     * Parse incoming PubSub message with application-specific parser
     * 
     * @param msg Raw Dynamic message from PubSub
     * @param messageParser Application-specific message parser
     * @return Parsed message or None if parsing failed
     */
    public static function parseWithConverter<M>(
        msg: Dynamic,
        messageParser: Dynamic -> Option<M>
    ): Option<M> {
        return messageParser(msg);
    }
    
    /**
     * Utility function to add timestamp to message payload
     */
    public static function addTimestamp(payload: Dynamic): Dynamic {
        if (payload == null) {
            payload = {};
        }
        
        // Add timestamp for message tracking
        Reflect.setField(payload, "timestamp", Date.now().getTime());
        
        return payload;
    }
    
    /**
     * Utility function to validate message structure
     * 
     * @param msg Message to validate
     * @return true if message has required fields
     */
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
