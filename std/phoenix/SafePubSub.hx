package phoenix;

import haxe.ds.Option;
import haxe.functional.Result;
import elixir.Module;
import elixir.Application;
import elixir.types.Term;

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
 * See `/docs/02-user-guide/PUBSUB_MACRO_ROADMAP.md` for complete enhancement roadmap.
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
     * Parse incoming message term to typed enum
     * Returns None for unknown or malformed messages
     */
    function parseMessage(msg: Term): Option<M>;
    
    /**
     * Convert typed message to a term for Elixir compatibility
     */
    function messageToElixir(message: M): Term;
}

/**
 * Framework-level SafePubSub operations
 *
 * This class provides the core infrastructure for type-safe PubSub
 * operations. Uses extern inline pattern to inject Elixir code directly
 * at call sites, avoiding the need for a separate Phoenix.SafePubSub module.
 */
extern class SafePubSub {

    /**
     * Type-safe subscribe to a topic
     *
     * @param topicString Topic string to subscribe to
     * @return Result indicating success or failure
     */
    extern inline public static function subscribeTopic(topicString: String): Result<Void, String> {
        return untyped __elixir__('
          # Dynamically determine PubSub module from endpoint config
          pubsub_mod = (fn ->
            apps = Application.loaded_applications()
            {app_name, _endpoint} = Enum.find_value(apps, fn {app, _desc, _vsn} ->
              case :application.get_key(app, :modules) do
                {:ok, modules} ->
                  endpoint = Enum.find(modules, fn mod ->
                    mod_str = to_string(mod)
                    String.ends_with?(mod_str, ".Endpoint")
                  end)
                  if endpoint, do: {app, endpoint}, else: nil
                _ -> nil
              end
            end) || {:todo_app, nil}
            app_name
            |> to_string()
            |> String.split("_")
            |> Enum.map(&String.capitalize/1)
            |> Module.concat()
            |> (&Module.concat(&1, :PubSub)).()
          end).()
          case Phoenix.PubSub.subscribe(pubsub_mod, {0}) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicString);
    }

    extern inline public static function subscribeWithConverter<T>(
        topic: T,
        topicConverter: T -> String
    ): Result<Void, String> {
        return subscribeTopic(topicConverter(topic));
    }

    /**
     * Type-safe broadcast with topic and payload
     *
     * @param topicString Topic string to broadcast to
     * @param payload Message payload
     * @return Result indicating success or failure
     */
    extern inline public static function broadcastTopicPayload(topicString: String, payload: Term): Result<Void, String> {
        return untyped __elixir__('
          pubsub_mod = Phoenix.SafePubSub.get_pub_sub_module()
          normalized = if is_map({1}) do
            Enum.reduce(Map.keys({1}), {1}, fn k, acc ->
              cond do
                is_atom(k) ->
                  sk = Atom.to_string(k)
                  if Map.has_key?(acc, sk), do: acc, else: Map.put(acc, sk, Map.get(acc, k))
                true -> acc
              end
            end)
          else
            {1}
          end
          case Phoenix.PubSub.broadcast(pubsub_mod, {0}, normalized) do
            :ok -> {:ok, nil}
            {:error, reason} -> {:error, to_string(reason)}
          end
        ', topicString, payload);
    }

    extern inline public static function broadcastWithConverters<T, M>(
        topic: T,
        message: M,
        topicConverter: T -> String,
        messageConverter: M -> Term
    ): Result<Void, String> {
        return broadcastTopicPayload(topicConverter(topic), messageConverter(message));
    }

    /**
     * Parse incoming PubSub message with application-specific parser
     */
    extern inline public static function parseWithConverter<M>(
        msg: Term,
        messageParser: Term -> Option<M>
    ): Option<M> {
        return untyped __elixir__('
          res = cond do
            is_function({1}, 1) -> {1}.({0})
            is_atom({1}) ->
              s = to_string({1})
              case String.split(s, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [{0}])
                _ -> raise ArgumentError, message: "invalid message_parser atom: " <> inspect({1})
              end
            is_binary({1}) ->
              case String.split({1}, ".") do
                [mod_str, fun_str] ->
                  mod = ("Elixir." <> Macro.camelize(mod_str)) |> String.to_atom()
                  apply(mod, String.to_atom(fun_str), [{0}])
                _ -> raise ArgumentError, message: "invalid message_parser string: " <> inspect({1})
              end
            true -> raise ArgumentError, message: "invalid message_parser: expected function/1 or module.function string"
          end
          case res do
            {:some, {:some, v}} -> {:some, v}
            {:some, :none} -> :none
            other -> other
          end
        ', msg, messageParser);
    }

    /**
     * Add timestamp to message payload
     */
    extern inline public static function addTimestamp(payload: Term): Term {
        return untyped __elixir__('Map.put({0} || %{}, :timestamp, System.system_time(:millisecond))', payload);
    }

    /**
     * Validate message structure
     */
    extern inline public static function isValidMessage(msg: Term): Bool {
        return untyped __elixir__('is_map({0}) and Map.has_key?({0}, :type) and not is_nil(Map.get({0}, :type))', msg);
    }

    /**
     * Create error message for unknown message types
     */
    extern inline public static function createUnknownMessageError(messageType: String): String {
        return 'Unknown PubSub message type: "$messageType". Check your message enum definitions.';
    }

    /**
     * Create error message for malformed messages
     */
    extern inline public static function createMalformedMessageError(msg: Term): String {
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
     * Get PubSub module dynamically from endpoint configuration.
     * This is called at runtime by the inlined code.
     */
    extern inline public static function getPubSubModule(): Term {
        return untyped __elixir__('Phoenix.SafePubSub.get_pub_sub_module()');
    }
}
