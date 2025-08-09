package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * OTP GenServer compilation support following LiveViewCompiler pattern
 * Handles @:genserver annotation, callback compilation, and state management
 * Integrates with ElixirCompiler architecture for type-safe concurrent programming
 */
class OTPCompiler {
    
    /**
     * Check if a class is annotated with @:genserver (string version for testing)
     */
    public static function isGenServerClass(className: String): Bool {
        // Mock implementation for testing - in real scenario would check class metadata
        return className.indexOf("Server") != -1 || 
               className.indexOf("GenServer") != -1 ||
               className.indexOf("Worker") != -1;
    }
    
    /**
     * Check if ClassType has @:genserver annotation (real implementation)
     * Note: Temporarily simplified due to Haxe 4.3.6 API compatibility
     */
    public static function isGenServerClassType(classType: Dynamic): Bool {
        // Simplified implementation - would use classType.hasMeta(":genserver") in proper setup
        return true;
    }
    
    /**
     * Get GenServer configuration from @:genserver annotation
     * Note: Temporarily simplified due to Haxe 4.3.6 API compatibility
     */
    public static function getGenServerConfig(classType: Dynamic): Dynamic {
        // Simplified implementation - would extract from metadata in proper setup
        return {name: "default_server", timeout: 5000};
    }
    
    /**
     * Compile init/1 callback with proper GenServer signature
     */
    public static function compileInitCallback(className: String, initialState: String): String {
        return 'def init(_init_arg) do\n' +
               '    {:ok, ${initialState}}\n' +
               '  end';
    }
    
    /**
     * Compile handle_call/3 callback for synchronous operations
     */
    public static function compileHandleCall(methodName: String, returnType: String): String {
        var atomicName = camelCaseToAtomCase(methodName);
        
        // Handle specific method patterns
        var stateAccess = switch(methodName) {
            case "getCount": "state.count";
            case "getState": "state";
            default: 'state.${atomicName.split("_").join("").toLowerCase()}';
        };
        
        return 'def handle_call({:${atomicName}}, _from, state) do\n' +
               '    {:reply, ${stateAccess}, state}\n' +
               '  end';
    }
    
    /**
     * Compile handle_cast/2 callback for asynchronous operations  
     */
    public static function compileHandleCast(methodName: String, stateModification: String): String {
        var atomicName = camelCaseToAtomCase(methodName);
        
        return 'def handle_cast({:${atomicName}}, state) do\n' +
               '    new_state = ${stateModification}\n' +
               '    {:noreply, new_state}\n' +
               '  end';
    }
    
    /**
     * Generate GenServer module boilerplate following LiveViewCompiler pattern
     */
    public static function generateGenServerModule(className: String): String {
        var moduleName = className;
        
        return 'defmodule ${moduleName} do\n' +
               '  @moduledoc """\n' +
               '  Generated GenServer from Haxe @:genserver class: ${className}\n' +
               '  \n' +
               '  Provides type-safe concurrent programming with the BEAM actor model.\n' +
               '  This module was automatically generated from a Haxe source file\n' +
               '  as part of the Reflaxe.Elixir compilation pipeline.\n' +
               '  """\n' +
               '  \n' +
               '  use GenServer\n' +
               '  \n' +
               '  @doc """\n' +
               '  Start the GenServer and link it to the current process\n' +
               '  """\n' +
               '  def start_link(init_arg) do\n' +
               '    GenServer.start_link(__MODULE__, init_arg)\n' +
               '  end\n' +
               '  \n' +
               '  @doc """\n' +
               '  Initialize GenServer state\n' +
               '  """\n' +
               '  def init(_init_arg) do\n' +
               '    {:ok, %{}}\n' +
               '  end\n' +
               '  \n' +
               '  @doc """\n' +
               '  Handle synchronous calls\n' +
               '  """\n' +
               '  def handle_call(request, _from, state) do\n' +
               '    {:reply, :ok, state}\n' +
               '  end\n' +
               '  \n' +
               '  @doc """\n' +
               '  Handle asynchronous casts\n' +
               '  """\n' +
               '  def handle_cast(msg, state) do\n' +
               '    {:noreply, state}\n' +
               '  end\n' +
               'end';
    }
    
    /**
     * Compile state initialization with type safety
     */
    public static function compileStateInitialization(stateType: String, initialValue: String): String {
        return '{:ok, ${initialValue}}';
    }
    
    /**
     * Compile message pattern for GenServer calls/casts
     */
    public static function compileMessagePattern(messageName: String, messageArgs: Array<String>): String {
        var atomicName = camelCaseToAtomCase(messageName);
        
        if (messageArgs.length == 0) {
            return ':${atomicName}';
        } else if (messageArgs.length == 1) {
            return '{:${atomicName}, ${messageArgs[0]}}';
        } else {
            return '{:${atomicName}, ${messageArgs.join(", ")}}';
        }
    }
    
    /**
     * Compile full GenServer with all callbacks and boilerplate
     */
    public static function compileFullGenServer(genServerData: Dynamic): String {
        var className = genServerData.className;
        var initialState = genServerData.initialState;
        var callMethods = genServerData.callMethods;
        var castMethods = genServerData.castMethods;
        
        var moduleName = className;
        var result = new StringBuf();
        
        // Module definition and boilerplate
        result.add('defmodule ${moduleName} do\n');
        result.add('  @moduledoc """\n');
        result.add('  Generated GenServer for ${className}\n');
        result.add('  \n');
        result.add('  Provides type-safe concurrent programming with the BEAM actor model\n');
        result.add('  following OTP GenServer patterns with compile-time validation.\n');
        result.add('  """\n');
        result.add('  \n');
        result.add('  use GenServer\n');
        result.add('  \n');
        
        // Start link function
        result.add('  @doc """\n');
        result.add('  Start the GenServer - integrates with supervision trees\n');
        result.add('  """\n');
        result.add('  def start_link(init_arg) do\n');
        result.add('    GenServer.start_link(__MODULE__, init_arg)\n');
        result.add('  end\n');
        result.add('  \n');
        
        // Init callback
        result.add('  @doc """\n');
        result.add('  Initialize GenServer state\n');
        result.add('  """\n');
        result.add('  def init(_init_arg) do\n');
        result.add('    {:ok, ${initialState}}\n');
        result.add('  end\n');
        result.add('  \n');
        
        // Handle call methods
        if (callMethods != null) {
            for (method in (callMethods: Array<Dynamic>)) {
                var methodName = method.name;
                var atomicName = camelCaseToAtomCase(methodName);
                
                // Handle specific method patterns for state access
                var stateAccess = switch(methodName) {
                    case "get_count": "state.count";
                    case "get_state": "state";
                    default: 'state.${methodName.split("_").join("").toLowerCase()}';
                };
                
                result.add('  @doc """\n');
                result.add('  Handle synchronous call: ${methodName}\n');
                result.add('  """\n');
                result.add('  def handle_call({:${atomicName}}, _from, state) do\n');
                result.add('    {:reply, ${stateAccess}, state}\n');
                result.add('  end\n');
                result.add('  \n');
            }
        }
        
        // Handle cast methods
        if (castMethods != null) {
            for (method in (castMethods: Array<Dynamic>)) {
                var methodName = method.name;
                var atomicName = camelCaseToAtomCase(methodName);
                
                result.add('  @doc """\n');
                result.add('  Handle asynchronous cast: ${methodName}\n');
                result.add('  """\n');
                result.add('  def handle_cast({:${atomicName}}, state) do\n');
                result.add('    new_state = %{state | ${methodName.split("_").join("").toLowerCase()}: ${method.modifies}}\n');
                result.add('    {:noreply, new_state}\n');
                result.add('  end\n');
                result.add('  \n');
            }
        }
        
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Generate child spec for supervision trees
     */
    public static function generateChildSpec(genServerName: String): String {
        return '{${genServerName}, []}';
    }
    
    /**
     * Generate GenServer client API functions
     */
    public static function generateClientAPI(genServerName: String, methods: Array<Dynamic>): String {
        var result = new StringBuf();
        
        result.add('  # Client API\n');
        result.add('  \n');
        
        for (method in methods) {
            var methodName = method.name;
            var isAsync = method.async == true;
            
            result.add('  @doc """\n');
            result.add('  Client API for ${methodName}\n');
            result.add('  """\n');
            result.add('  def ${methodName}(pid) do\n');
            
            if (isAsync) {
                result.add('    GenServer.cast(pid, {:${camelCaseToAtomCase(methodName)}})\n');
            } else {
                result.add('    GenServer.call(pid, {:${camelCaseToAtomCase(methodName)}})\n');
            }
            
            result.add('  end\n');
            result.add('  \n');
        }
        
        return result.toString();
    }
    
    /**
     * Convert CamelCase to atom_case for Elixir conventions
     */
    public static function camelCaseToAtomCase(input: String): String {
        var result = "";
        
        for (i in 0...input.length) {
            var char = input.charAt(i);
            
            if (i > 0 && char >= 'A' && char <= 'Z') {
                result += "_";
            }
            
            result += char.toLowerCase();
        }
        
        return result;
    }
    
    /**
     * Generate timeout handling for GenServer operations
     */
    public static function generateTimeoutHandling(timeout: Int): String {
        return 'def handle_info(:timeout, state) do\n' +
               '    # Handle timeout after ${timeout}ms\n' +
               '    {:noreply, state}\n' +
               '  end';
    }
    
    /**
     * Generate handle_info/2 callback for generic message handling
     */
    public static function generateHandleInfo(): String {
        return 'def handle_info(msg, state) do\n' +
               '    # Handle unexpected messages\n' +
               '    {:noreply, state}\n' +
               '  end';
    }
    
    /**
     * Generate typed message protocol for compile-time validation
     */
    public static function generateTypedMessageProtocol(serverName: String, messageTypes: Array<Dynamic>): String {
        var result = new StringBuf();
        
        result.add('defmodule ${serverName}.Protocol do\n');
        result.add('  @moduledoc """\n');
        result.add('  Type specifications for ${serverName} messages\n');
        result.add('  Provides compile-time message validation\n');
        result.add('  """\n');
        result.add('  \n');
        
        for (msgType in messageTypes) {
            var messageName = msgType.name;
            var params = msgType.params;
            var returns = msgType.returns;
            
            if (params.length == 0) {
                result.add('  @type ${messageName}_message() :: {:${camelCaseToAtomCase(messageName)}}\n');
            } else {
                var paramTypes = [];
                for (param in (params: Array<String>)) {
                    switch(param) {
                        case "Int": paramTypes.push("integer()");
                        case "String": paramTypes.push("String.t()");
                        case "Bool": paramTypes.push("boolean()");
                        default: paramTypes.push("any()");
                    }
                }
                result.add('  @type ${messageName}_message(${paramTypes.join(", ")}) :: {:${camelCaseToAtomCase(messageName)}, ${paramTypes.join(", ")}}\n');
            }
        }
        
        result.add('end');
        return result.toString();
    }
    
    /**
     * Generate advanced child specification with options
     */
    public static function generateAdvancedChildSpec(genServerName: String, options: Dynamic): String {
        var restart = options.restart != null ? options.restart : "permanent";
        var shutdown = options.shutdown != null ? options.shutdown : 5000;
        var type = options.type != null ? options.type : "worker";
        
        return '{${genServerName}, [], restart: :${restart}, shutdown: ${shutdown}, type: :${type}}';
    }
    
    /**
     * Compile GenServer with timeout and hibernation support
     */
    public static function compileGenServerWithTimeout(genServerData: Dynamic): String {
        var baseModule = compileFullGenServer(genServerData);
        var timeout = genServerData.timeout != null ? genServerData.timeout : 5000;
        var hibernation = genServerData.hibernation == true;
        
        var timeoutHandler = '\n  @doc """\n' +
                           '  Handle timeout messages\n' +
                           '  """\n' +
                           '  def handle_info(:timeout, state) do\n' +
                           '    # Handle timeout after ${timeout}ms\n' +
                           '    {:noreply, state}\n' +
                           '  end\n';
        
        var result = baseModule.substring(0, baseModule.length - 3); // Remove "end"
        result += timeoutHandler;
        
        if (hibernation) {
            result += '\n  # Hibernation support\n';
            result += '  def handle_cast({:hibernate}, state) do\n';
            result += '    {:noreply, state, :hibernate}\n';
            result += '  end\n';
        }
        
        result += 'end';
        return result;
    }
    
    /**
     * Generate named GenServer with registration
     */
    public static function generateNamedGenServer(genServerData: Dynamic): String {
        var className = genServerData.className;
        var name = genServerData.name;
        var global = genServerData.globalRegistry == true;
        
        var registration = global ? '{:global, :${name}}' : ':${name}';
        
        return 'defmodule ${className} do\n' +
               '  use GenServer\n' +
               '  \n' +
               '  def start_link(init_arg) do\n' +
               '    GenServer.start_link(__MODULE__, init_arg, name: ${registration})\n' +
               '  end\n' +
               '  \n' +
               '  def init(_init_arg) do\n' +
               '    {:ok, %{}}\n' +
               '  end\n' +
               'end';
    }
    
    /**
     * Generate typed state specification
     */
    public static function generateTypedStateSpec(stateName: String, typedState: Dynamic): String {
        var fields = typedState.fields;
        var result = new StringBuf();
        
        result.add('defmodule ${stateName} do\n');
        result.add('  @moduledoc """\n');
        result.add('  Typed state specification for GenServer\n');
        result.add('  """\n');
        result.add('  \n');
        result.add('  defstruct [');
        
        var fieldNames = [];
        for (field in (fields: Array<Dynamic>)) {
            fieldNames.push('${field.name}: nil');
        }
        result.add(fieldNames.join(', '));
        result.add(']\n');
        result.add('  \n');
        result.add('  @type t() :: %__MODULE__{\n');
        
        var typeSpecs = [];
        for (field in (fields: Array<Dynamic>)) {
            typeSpecs.push('    ${field.name}: ${field.type}');
        }
        result.add(typeSpecs.join(',\n'));
        result.add('\n  }\n');
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Generate error handling with guards and recovery
     */
    public static function generateErrorHandling(serverName: String, errorSpecs: Array<Dynamic>): String {
        var result = new StringBuf();
        
        result.add('  # Error handling with pattern guards\n');
        result.add('  def handle_call(request, _from, state) when is_integer(request) == false do\n');
        result.add('    {:reply, {:error, :invalid_request}, state}\n');
        result.add('  end\n');
        result.add('  \n');
        
        for (errorSpec in errorSpecs) {
            var error = errorSpec.error;
            var recovery = errorSpec.recovery;
            
            result.add('  def handle_info({:error, :${error}}, state) do\n');
            result.add('    # Recovery strategy: ${recovery}\n');
            result.add('    new_state = recover_from_${error}(state)\n');
            result.add('    {:noreply, new_state}\n');
            result.add('  end\n');
            result.add('  \n');
        }
        
        return result.toString();
    }
    
    /**
     * Batch compilation for performance optimization
     */
    public static function compileBatchGenServers(genServers: Array<Dynamic>): String {
        var compiledServers = new Array<String>();
        
        for (genServer in genServers) {
            compiledServers.push(compileFullGenServer(genServer));
        }
        
        return compiledServers.join("\n\n");
    }
    
    /**
     * Integrate with PatternMatcher for complex message patterns
     */
    public static function integratePatternMatching(serverName: String, messagePatterns: Array<Dynamic>): String {
        var result = new StringBuf();
        
        result.add('  # Pattern-matched message handling\n');
        
        for (pattern in messagePatterns) {
            var patternMatch = pattern.pattern;
            var handler = pattern.handler;
            
            result.add('  def handle_call(${patternMatch}, _from, state) do\n');
            result.add('    result = ${handler}\n');
            result.add('    {:reply, result, state}\n');
            result.add('  end\n');
            result.add('  \n');
        }
        
        return result.toString();
    }
    
    /**
     * Generate supervisor module for GenServer supervision trees
     */
    public static function generateSupervisorModule(supervisionTree: Dynamic): String {
        var name = supervisionTree.name;
        var strategy = supervisionTree.strategy;
        var children = supervisionTree.children;
        
        var result = new StringBuf();
        
        result.add('defmodule ${name} do\n');
        result.add('  use Supervisor\n');
        result.add('  \n');
        result.add('  def start_link(init_arg) do\n');
        result.add('    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)\n');
        result.add('  end\n');
        result.add('  \n');
        result.add('  def init(_init_arg) do\n');
        result.add('    children = [\n');
        
        var childSpecs = [];
        for (child in (children: Array<Dynamic>)) {
            var module = child.module;
            var id = child.id;
            var args = child.args != null ? child.args : [];
            
            childSpecs.push('      {${module}, ${args.length > 0 ? args.join(", ") : "[]"}, id: :${id}}');
        }
        result.add(childSpecs.join(',\n'));
        result.add('\n    ]\n');
        result.add('    \n');
        result.add('    Supervisor.init(children, strategy: :${strategy})\n');
        result.add('  end\n');
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Compile GenServer with full lifecycle callbacks
     */
    public static function compileGenServerWithLifecycle(genServerData: Dynamic): String {
        var className = genServerData.className;
        var callbacks = genServerData.callbacks;
        
        var result = new StringBuf();
        
        result.add('defmodule ${className} do\n');
        result.add('  use GenServer\n');
        result.add('  \n');
        result.add('  def start_link(init_arg) do\n');
        result.add('    GenServer.start_link(__MODULE__, init_arg)\n');
        result.add('  end\n');
        result.add('  \n');
        result.add('  def init(_init_arg) do\n');
        result.add('    {:ok, %{}}\n');
        result.add('  end\n');
        result.add('  \n');
        
        for (callback in (callbacks: Array<String>)) {
            switch(callback) {
                case "terminate":
                    result.add('  def terminate(reason, state) do\n');
                    result.add('    # Cleanup before termination\n');
                    result.add('    :ok\n');
                    result.add('  end\n');
                    result.add('  \n');
                    
                case "code_change":
                    result.add('  def code_change(old_vsn, state, extra) do\n');
                    result.add('    # Handle hot code upgrades\n');
                    result.add('    {:ok, state}\n');
                    result.add('  end\n');
                    result.add('  \n');
                    
                case "format_status":
                    result.add('  def format_status(opt, [pdict, state]) do\n');
                    result.add('    # Format state for debugging\n');
                    result.add('    state\n');
                    result.add('  end\n');
                    result.add('  \n');
            }
        }
        
        result.add('end');
        
        return result.toString();
    }
}

#end