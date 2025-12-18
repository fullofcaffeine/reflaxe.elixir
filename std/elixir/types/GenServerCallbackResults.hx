package elixir.types;

import elixir.types.Term;

/**
 * Type-safe result types for GenServer callbacks
 * 
 * These enums provide compile-time safety for GenServer callback return values,
 * ensuring all possible return patterns are handled correctly.
 */

/**
 * Result type for init/1 callback
 * 
 * @param S The type of the GenServer state
 */
enum InitResult<S> {
    /**
     * Successful initialization
     * Compiles to: {:ok, state}
     */
    Ok(state: S);
    
    /**
     * Successful initialization with timeout
     * Compiles to: {:ok, state, timeout}
     */
    OkTimeout(state: S, timeout: Int);
    
    /**
     * Successful initialization with hibernation
     * Compiles to: {:ok, state, :hibernate}
     */
    OkHibernate(state: S);
    
    /**
     * Successful initialization with continue
     * Compiles to: {:ok, state, {:continue, term}}
     */
    OkContinue(state: S, continueArg: Term);
    
    /**
     * Stop the GenServer immediately
     * Compiles to: {:stop, reason}
     */
    Stop(reason: Term);
    
    /**
     * Ignore this GenServer start
     * Compiles to: :ignore
     */
    Ignore;
}

/**
 * Result type for handle_call/3 callback
 * 
 * @param R The type of the reply to send back to the caller
 * @param S The type of the GenServer state
 */
enum HandleCallResult<R, S> {
    /**
     * Reply with a value and update state
     * Compiles to: {:reply, reply, new_state}
     */
    Reply(reply: R, newState: S);
    
    /**
     * Reply with timeout
     * Compiles to: {:reply, reply, new_state, timeout}
     */
    ReplyTimeout(reply: R, newState: S, timeout: Int);
    
    /**
     * Reply and hibernate
     * Compiles to: {:reply, reply, new_state, :hibernate}
     */
    ReplyHibernate(reply: R, newState: S);
    
    /**
     * Reply and continue
     * Compiles to: {:reply, reply, new_state, {:continue, term}}
     */
    ReplyContinue(reply: R, newState: S, continueArg: Term);
    
    /**
     * Don't reply yet (will reply later with GenServer.reply)
     * Compiles to: {:noreply, new_state}
     */
    NoReply(newState: S);
    
    /**
     * Don't reply with timeout
     * Compiles to: {:noreply, new_state, timeout}
     */
    NoReplyTimeout(newState: S, timeout: Int);
    
    /**
     * Don't reply and hibernate
     * Compiles to: {:noreply, new_state, :hibernate}
     */
    NoReplyHibernate(newState: S);
    
    /**
     * Don't reply and continue
     * Compiles to: {:noreply, new_state, {:continue, term}}
     */
    NoReplyContinue(newState: S, continueArg: Term);
    
    /**
     * Stop and reply
     * Compiles to: {:stop, reason, reply, new_state}
     */
    StopReply(reason: Term, reply: R, newState: S);
    
    /**
     * Stop without replying
     * Compiles to: {:stop, reason, new_state}
     */
    Stop(reason: Term, newState: S);
}

/**
 * Result type for handle_cast/2 callback
 * 
 * @param S The type of the GenServer state
 */
enum HandleCastResult<S> {
    /**
     * Continue with updated state
     * Compiles to: {:noreply, new_state}
     */
    NoReply(newState: S);
    
    /**
     * Continue with timeout
     * Compiles to: {:noreply, new_state, timeout}
     */
    NoReplyTimeout(newState: S, timeout: Int);
    
    /**
     * Continue and hibernate
     * Compiles to: {:noreply, new_state, :hibernate}
     */
    NoReplyHibernate(newState: S);
    
    /**
     * Continue with continue argument
     * Compiles to: {:noreply, new_state, {:continue, term}}
     */
    NoReplyContinue(newState: S, continueArg: Term);
    
    /**
     * Stop the GenServer
     * Compiles to: {:stop, reason, new_state}
     */
    Stop(reason: Term, newState: S);
}

/**
 * Result type for handle_info/2 callback
 * Same as HandleCastResult since they have identical return patterns
 * 
 * @param S The type of the GenServer state
 */
typedef HandleInfoResult<S> = HandleCastResult<S>;

/**
 * Result type for handle_continue/2 callback
 * Same as HandleCastResult since they have identical return patterns
 * 
 * @param S The type of the GenServer state
 */
typedef HandleContinueResult<S> = HandleCastResult<S>;

/**
 * Helper class for building callback results
 */
class CallbackResultBuilder {
    /**
     * Create a simple ok result for init
     */
    public static inline function initOk<S>(state: S): InitResult<S> {
        return InitResult.Ok(state);
    }
    
    /**
     * Create a reply result for handle_call
     */
    public static inline function reply<R, S>(reply: R, state: S): HandleCallResult<R, S> {
        return HandleCallResult.Reply(reply, state);
    }
    
    /**
     * Create a noreply result for handle_cast/handle_info
     */
    public static inline function noreply<S>(state: S): HandleCastResult<S> {
        return HandleCastResult.NoReply(state);
    }
    
    /**
     * Create a stop result with normal reason
     */
    public static inline function stopNormal<S>(state: S): HandleCastResult<S> {
        return HandleCastResult.Stop(untyped __elixir__(':normal'), state);
    }
    
    /**
     * Create a stop result with shutdown reason
     */
    public static inline function stopShutdown<S>(state: S): HandleCastResult<S> {
        return HandleCastResult.Stop(untyped __elixir__(':shutdown'), state);
    }
}
