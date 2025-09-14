defmodule Mix.Tasks.Haxe.Gen.Live do
  @shortdoc "Generates Phoenix LiveView modules with real-time features"
  
  @moduledoc """
  Generates Phoenix LiveView modules with mount/3, handle_event/3, handle_info/2, and render/1 functions.
  
  ## Usage
  
      mix haxe.gen.live ModuleName [options]
      
  ## Examples
  
      # Basic LiveView module
      mix haxe.gen.live Dashboard
      
      # LiveView with context and schema
      mix haxe.gen.live UserLive --context Accounts --schema User
      
      # LiveView with CRUD actions
      mix haxe.gen.live PostLive --context Blog --schema Post --actions index,show,new,edit
      
      # LiveView with real-time features
      mix haxe.gen.live ChatRoom --context Chat --schema Message --pubsub --presence
      
      # LiveView with custom events
      mix haxe.gen.live GameLive --events "start_game,make_move,end_game"
      
  ## Options
  
    * `--context` - The context module that contains business logic
    * `--schema` - The schema module to work with  
    * `--actions` - CRUD actions to generate (index,show,new,edit,delete)
    * `--events` - Custom event handlers to generate (comma-separated)
    * `--pubsub` - Include PubSub integration for real-time updates
    * `--presence` - Include Phoenix.Presence for user tracking
    * `--components` - Generate reusable function components
    * `--modal` - Include modal functionality
    * `--table` - Generate data table with sorting/filtering
    * `--form` - Generate form with validation
    * `--haxe-dir` - Haxe source directory (default: src_haxe/live)
    * `--elixir-dir` - Elixir output directory (default: lib/live)
    * `--no-heex` - Skip HEEx template generation
    * `--assigns` - Initial assigns for socket (comma-separated key:type pairs)
  """
  
  use Mix.Task
  
  @requirements ["app.config"]
  
  @impl Mix.Task
  def run(args) do
    {opts, parsed_args, _errors} = OptionParser.parse(args, 
      switches: [
        context: :string,
        schema: :string,
        actions: :string,
        events: :string,
        pubsub: :boolean,
        presence: :boolean,
        components: :boolean,
        modal: :boolean,
        table: :boolean,
        form: :boolean,
        haxe_dir: :string,
        elixir_dir: :string,
        no_heex: :boolean,
        assigns: :string
      ],
      aliases: [
        c: :context,
        s: :schema,
        a: :actions,
        e: :events
      ]
    )
    
    case parsed_args do
      [module_name] ->
        generate_liveview(module_name, opts)
      [] ->
        Mix.raise("Module name is required. Usage: mix haxe.gen.live ModuleName")
      _ ->
        Mix.raise("Too many arguments. Usage: mix haxe.gen.live ModuleName [options]")
    end
  end
  
  defp generate_liveview(module_name, opts) do
    # Parse options
    context = Keyword.get(opts, :context)
    schema = Keyword.get(opts, :schema)
    actions = parse_actions(Keyword.get(opts, :actions, ""))
    events = parse_events(Keyword.get(opts, :events, ""))
    pubsub = Keyword.get(opts, :pubsub, false)
    presence = Keyword.get(opts, :presence, false)
    components = Keyword.get(opts, :components, false)
    modal = Keyword.get(opts, :modal, false)
    table = Keyword.get(opts, :table, false)
    form = Keyword.get(opts, :form, false)
    haxe_dir = Keyword.get(opts, :haxe_dir, "src_haxe/live")
    elixir_dir = Keyword.get(opts, :elixir_dir, "lib/live")
    no_heex = Keyword.get(opts, :no_heex, false)
    assigns = parse_assigns(Keyword.get(opts, :assigns, ""))
    
    # Generate file paths
    snake_name = Macro.underscore(module_name)
    haxe_file = Path.join(haxe_dir, "#{module_name}.hx")
    elixir_file = Path.join(elixir_dir, "#{snake_name}.ex")
    
    # Ensure directories exist
    File.mkdir_p!(haxe_dir)
    File.mkdir_p!(elixir_dir)
    
    # Generate Haxe LiveView
    haxe_content = generate_haxe_liveview(module_name, %{
      context: context,
      schema: schema,
      actions: actions,
      events: events,
      pubsub: pubsub,
      presence: presence,
      components: components,
      modal: modal,
      table: table,
      form: form,
      assigns: assigns,
      no_heex: no_heex
    })
    
    # Generate Elixir LiveView
    elixir_content = generate_elixir_liveview(module_name, %{
      context: context,
      schema: schema,
      actions: actions,
      events: events,
      pubsub: pubsub,
      presence: presence,
      components: components,
      modal: modal,
      table: table,
      form: form,
      assigns: assigns,
      no_heex: no_heex
    })
    
    # Write files
    File.write!(haxe_file, haxe_content)
    File.write!(elixir_file, elixir_content)
    
    Mix.shell().info("""
    
    Generated LiveView files:
    
    * #{haxe_file} - Haxe source with @:liveview annotation
    * #{elixir_file} - Compiled Elixir LiveView module
    
    #{if context && schema do
      """
      The LiveView is configured to work with:
      * Context: #{context}
      * Schema: #{schema}
      
      Make sure these modules exist or generate them with:
          mix haxe.gen.context #{context} #{schema} #{Macro.underscore(schema) <> "s"}
      """
    else
      ""
    end}
    
    To use this LiveView in your router:
    
        live "/#{Macro.underscore(module_name)}", #{module_name}
    
    #{if pubsub do
      """
      PubSub integration is enabled. Configure your endpoint:
      
          config :my_app, MyAppWeb.Endpoint,
            pubsub_server: MyApp.PubSub
      """
    else
      ""
    end}
    
    #{if presence do
      """
      Presence tracking is enabled. Add to your supervision tree:
      
          children = [
            {Phoenix.Presence, name: MyApp.Presence}
          ]
      """
    else
      ""
    end}
    """)
  end
  
  defp generate_haxe_liveview(module_name, config) do
    """
    package live;
    
    #{if config.context && config.schema do
      "import contexts.#{config.context};\nimport contexts.#{config.context}.#{config.schema};"
    else
      ""
    end}
    
    #{unless config.no_heex do
      "// Import HXX for template processing\nimport HXX.*;"
    else
      ""
    end}
    
    /**
     * Phoenix LiveView module for #{module_name}
     * Generated by mix haxe.gen.live
     */
    @:liveview#{if config.pubsub || config.presence do
      "({pubsub: #{config.pubsub}, presence: #{config.presence}})"
    else
      ""
    end}
    class #{module_name} {
        #{generate_haxe_assigns(config.assigns)}
        #{if config.schema do
          """
          var #{String.downcase(config.schema) <> "s"}: Array<#{config.schema}> = [];
          var selected#{config.schema}: Null<#{config.schema}> = null;
          var changeset: Dynamic = null;
          """
        else
          ""
        end}
        #{if config.modal do
          "var showModal: Bool = false;"
        else
          ""
        end}
        #{if config.table do
          """
          var sortBy: String = "id";
          var sortOrder: String = "asc";
          var filterText: String = "";
          var currentPage: Int = 1;
          var perPage: Int = 10;
          """
        else
          ""
        end}
        
        function mount(params: Dynamic, session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
            #{generate_mount_body(config)}
            
            return {
                status: "ok",
                socket: assign_multiple(socket, {
                    #{generate_initial_assigns(config)}
                })
            };
        }
        
        function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
            return switch(event) {
                #{generate_event_cases(config)}
                
                default:
                    {status: "noreply", socket: socket};
            }
        }
        
        #{generate_event_handlers(config)}
        
        #{if config.pubsub do
          generate_handle_info(config)
        else
          ""
        end}
        
        #{unless config.no_heex do
          generate_render_function(config)
        else
          ""
        end}
        
        #{if config.components do
          generate_function_components(config)
        else
          ""
        end}
        
        // Helper functions
        static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic return socket;
        static function assign_multiple(socket: Dynamic, assigns: Dynamic): Dynamic return socket;
        #{if config.pubsub do
          """
          static function subscribe(topic: String): Void {}
          static function broadcast(topic: String, event: String, payload: Dynamic): Void {}
          """
        else
          ""
        end}
        #{if config.presence do
          """
          static function track(socket: Dynamic, userId: String, meta: Dynamic): Dynamic return socket;
          static function list_presence(socket: Dynamic): Array<Dynamic> return [];
          """
        else
          ""
        end}
        
        public static function main(): Void {
            trace("#{module_name} LiveView compiled successfully!");
        }
    }
    """
  end
  
  defp generate_elixir_liveview(module_name, config) do
    app_name = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    
    """
    defmodule #{app_name}Web.#{module_name} do
      use #{app_name}Web, :live_view
      
      #{if config.context && config.schema do
        "alias #{app_name}.#{config.context}\n  alias #{app_name}.#{config.context}.#{config.schema}"
      else
        ""
      end}
      #{if config.pubsub do
        "alias Phoenix.PubSub"
      else
        ""
      end}
      #{if config.presence do
        "alias #{app_name}.Presence"
      else
        ""
      end}
      
      @impl true
      def mount(params, session, socket) do
        #{generate_elixir_mount(config)}
        
        {:ok,
         socket
         |> assign(:page_title, "#{module_name}")
         #{generate_elixir_initial_assigns(config)}}
      end
      
      #{generate_elixir_event_handlers(config)}
      
      #{if config.pubsub do
        generate_elixir_handle_info(config)
      else
        ""
      end}
      
      #{unless config.no_heex do
        generate_elixir_render(config)
      else
        ""
      end}
      
      #{if config.components do
        generate_elixir_components(config)
      else
        ""
      end}
      
      #{generate_private_functions(config)}
    end
    """
  end
  
  # Helper functions for parsing options
  defp parse_actions(""), do: []
  defp parse_actions(actions_str) do
    actions_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
  end
  
  defp parse_events(""), do: []
  defp parse_events(events_str) do
    events_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
  
  defp parse_assigns(""), do: []
  defp parse_assigns(assigns_str) do
    assigns_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn assign ->
      case String.split(assign, ":") do
        [key, type] -> {String.to_atom(key), String.to_atom(type)}
        [key] -> {String.to_atom(key), :string}
      end
    end)
  end
  
  # Haxe generation helpers
  defp generate_haxe_assigns(assigns) do
    assigns
    |> Enum.map(fn {key, type} ->
      haxe_type = case type do
        :string -> "String"
        :integer -> "Int"
        :float -> "Float"
        :boolean -> "Bool"
        :array -> "Array<Dynamic>"
        :map -> "Dynamic"
        _ -> "Dynamic"
      end
      "var #{key}: #{haxe_type} = #{default_value_for_type(type)};"
    end)
    |> Enum.join("\n    ")
  end
  
  defp generate_mount_body(config) do
    body = []
    
    body = if config.schema && config.context do
      ["#{String.downcase(config.schema) <> "s"} = #{config.context}.list_#{String.downcase(config.schema) <> "s"}();" | body]
    else
      body
    end
    
    body = if config.pubsub do
      ["subscribe(\"#{String.downcase(config.schema || "updates")}\");" | body]
    else
      body
    end
    
    body = if config.presence do
      ["track(socket, session.user_id, {online_at: Date.now()});" | body]
    else
      body
    end
    
    Enum.join(Enum.reverse(body), "\n        ")
  end
  
  defp generate_initial_assigns(config) do
    assigns = config.assigns
    |> Enum.map(fn {key, _type} ->
      "#{key}: #{key}"
    end)
    
    assigns = if config.schema do
      schema_name = String.downcase(config.schema)
      [
        "#{schema_name}s: #{schema_name}s",
        "selected#{config.schema}: null",
        "changeset: null"
      ] ++ assigns
    else
      assigns
    end
    
    assigns = if config.modal do
      ["showModal: false" | assigns]
    else
      assigns
    end
    
    assigns = if config.table do
      [
        "sortBy: \"id\"",
        "sortOrder: \"asc\"",
        "filterText: \"\"",
        "currentPage: 1",
        "perPage: 10"
      ] ++ assigns
    else
      assigns
    end
    
    Enum.join(assigns, ",\n                    ")
  end
  
  defp generate_event_cases(config) do
    cases = []
    
    cases = if :index in config.actions do
      ["case \"load_#{String.downcase(config.schema || "items")}\": handle_load(params, socket);" | cases]
    else
      cases
    end
    
    cases = if :new in config.actions do
      ["case \"new_#{String.downcase(config.schema || "item")}\": handle_new(params, socket);" | cases]
    else
      cases
    end
    
    cases = if :edit in config.actions do
      ["case \"edit_#{String.downcase(config.schema || "item")}\": handle_edit(params, socket);" | cases]
    else
      cases
    end
    
    cases = if :delete in config.actions do
      ["case \"delete_#{String.downcase(config.schema || "item")}\": handle_delete(params, socket);" | cases]
    else
      cases
    end
    
    cases = if config.form do
      ["case \"save\": handle_save(params, socket);" | cases]
    else
      cases
    end
    
    cases = if config.table do
      [
        "case \"sort\": handle_sort(params, socket);",
        "case \"filter\": handle_filter(params, socket);",
        "case \"paginate\": handle_paginate(params, socket);"
      ] ++ cases
    else
      cases
    end
    
    cases = if config.modal do
      ["case \"close_modal\": handle_close_modal(socket);" | cases]
    else
      cases
    end
    
    cases = config.events
    |> Enum.map(fn event ->
      "case \"#{event}\": handle_#{String.replace(event, "-", "_")}(params, socket);"
    end)
    |> Kernel.++(cases)
    
    Enum.join(Enum.reverse(cases), "\n                ")
  end
  
  defp generate_event_handlers(config) do
    handlers = []
    
    handlers = if :new in config.actions && config.schema do
      [generate_new_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if :edit in config.actions && config.schema do
      [generate_edit_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if :delete in config.actions && config.schema do
      [generate_delete_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if config.form && config.schema do
      [generate_save_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = config.events
    |> Enum.map(fn event ->
      """
      function handle_#{String.replace(event, "-", "_")}(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
          // TODO: Implement #{event} handler
          return {status: "noreply", socket: socket};
      }
      """
    end)
    |> Kernel.++(handlers)
    
    Enum.join(Enum.reverse(handlers), "\n    ")
  end
  
  defp generate_new_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    function handle_new(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        changeset = #{config.context}.change_#{schema_lower}(null);
        selected#{config.schema} = null;
        #{if config.modal do
          "showModal = true;"
        else
          ""
        end}
        
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                changeset: changeset,
                selected#{config.schema}: null#{if config.modal do
                  ",\n                showModal: true"
                else
                  ""
                end}
            })
        };
    }
    """
  end
  
  defp generate_edit_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    function handle_edit(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var id = params.id;
        selected#{config.schema} = #{config.context}.get_#{schema_lower}(id);
        changeset = #{config.context}.change_#{schema_lower}(selected#{config.schema});
        #{if config.modal do
          "showModal = true;"
        else
          ""
        end}
        
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                selected#{config.schema}: selected#{config.schema},
                changeset: changeset#{if config.modal do
                  ",\n                showModal: true"
                else
                  ""
                end}
            })
        };
    }
    """
  end
  
  defp generate_delete_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    function handle_delete(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var id = params.id;
        var #{schema_lower} = #{config.context}.get_#{schema_lower}(id);
        var result = #{config.context}.delete_#{schema_lower}(#{schema_lower});
        
        if (result.status == "ok") {
            #{schema_lower}s = #{config.context}.list_#{schema_lower}s();
            
            return {
                status: "noreply",
                socket: assign(socket, "#{schema_lower}s", #{schema_lower}s)
            };
        }
        
        return {status: "noreply", socket: socket};
    }
    """
  end
  
  defp generate_save_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    function handle_save(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var #{schema_lower}_params = params.#{schema_lower};
        var result = selected#{config.schema} == null
            ? #{config.context}.create_#{schema_lower}(#{schema_lower}_params)
            : #{config.context}.update_#{schema_lower}(selected#{config.schema}, #{schema_lower}_params);
            
        return switch(result.status) {
            case "ok":
                #{schema_lower}s = #{config.context}.list_#{schema_lower}s();
                #{if config.modal do
                  "showModal = false;"
                else
                  ""
                end}
                
                {
                    status: "noreply",
                    socket: assign_multiple(socket, {
                        #{schema_lower}s: #{schema_lower}s,
                        selected#{config.schema}: null,
                        changeset: null#{if config.modal do
                          ",\n                        showModal: false"
                        else
                          ""
                        end}
                    })
                };
                
            case "error":
                {
                    status: "noreply",
                    socket: assign(socket, "changeset", result.changeset)
                };
                
            default:
                {status: "noreply", socket: socket};
        }
    }
    """
  end
  
  defp generate_handle_info(config) do
    """
    function handle_info(msg: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return switch(msg.event) {
            case "#{String.downcase(config.schema || "item")}_created":
                var #{String.downcase(config.schema || "items")} = #{config.context || "Context"}.list_#{String.downcase(config.schema || "items")}();
                {
                    status: "noreply",
                    socket: assign(socket, "#{String.downcase(config.schema || "items")}", #{String.downcase(config.schema || "items")})
                };
                
            case "#{String.downcase(config.schema || "item")}_updated":
                var #{String.downcase(config.schema || "items")} = #{config.context || "Context"}.list_#{String.downcase(config.schema || "items")}();
                {
                    status: "noreply",
                    socket: assign(socket, "#{String.downcase(config.schema || "items")}", #{String.downcase(config.schema || "items")})
                };
                
            default:
                {status: "noreply", socket: socket};
        }
    }
    """
  end
  
  defp generate_render_function(config) do
    """
    function render(assigns: Dynamic): String {
        return hxx('
        <div class="#{String.downcase(config.schema || "container")}">
            <div class="header">
                <h1>#{config.schema || "LiveView"} Management</h1>
                #{if :new in config.actions do
                  """
                  <.button phx-click="new_#{String.downcase(config.schema || "item")}" class="btn-primary">
                      <.icon name="plus" /> New #{config.schema || "Item"}
                  </.button>
                  """
                else
                  ""
                end}
            </div>
            
            #{if config.table do
              generate_table_template(config)
            else
              ""
            end}
            
            #{if config.modal do
              generate_modal_template(config)
            else
              ""
            end}
        </div>
        ');
    }
    """
  end
  
  defp generate_table_template(_config) do
    """
    <div class="data-table">
        <div class="table-controls">
            <.form phx-change="filter">
                <.input 
                    name="filter"
                    value={@filterText}
                    placeholder="Filter..."
                    type="search"
                />
            </.form>
        </div>
        
        <table class="table">
            <thead>
                <tr>
                    <th phx-click="sort" phx-value-field="id">
                        ID {@sortBy == "id" ? (@sortOrder == "asc" ? "↑" : "↓") : ""}
                    </th>
                    <th phx-click="sort" phx-value-field="name">
                        Name {@sortBy == "name" ? (@sortOrder == "asc" ? "↑" : "↓") : ""}
                    </th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <!-- Render table rows here -->
            </tbody>
        </table>
        
        <div class="pagination">
            <.button phx-click="paginate" phx-value-page={@currentPage - 1} disabled={@currentPage == 1}>
                Previous
            </.button>
            <span>Page {@currentPage}</span>
            <.button phx-click="paginate" phx-value-page={@currentPage + 1}>
                Next
            </.button>
        </div>
    </div>
    """
  end
  
  defp generate_modal_template(_config) do
    """
    ${@showModal ? renderModal(assigns) : ""}
    """
  end
  
  defp generate_function_components(config) do
    """
    function renderModal(assigns: Dynamic): String {
        return hxx('
        <div class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>{@selectedItem == null ? "New" : "Edit"} ${config.schema || "Item"}</h2>
                    <button phx-click="close_modal" class="close">&times;</button>
                </div>
                
                <.form for={@changeset} phx-submit="save">
                    <!-- Form fields here -->
                    
                    <div class="form-actions">
                        <.button type="submit">Save</.button>
                        <.button type="button" phx-click="close_modal" variant="secondary">
                            Cancel
                        </.button>
                    </div>
                </.form>
            </div>
        </div>
        ');
    }
    """
  end
  
  # Elixir generation helpers
  defp generate_elixir_mount(config) do
    mount_body = []
    
    mount_body = if config.pubsub do
      topic = String.downcase(config.schema || "updates")
      ["Phoenix.PubSub.subscribe(#{Mix.Project.config()[:app] |> to_string() |> Macro.camelize()}.PubSub, \"#{topic}\")" | mount_body]
    else
      mount_body
    end
    
    mount_body = if config.presence do
      ["if connected?(socket), do: Presence.track(self(), \"users:online\", socket.assigns.current_user_id || \"guest\", %{online_at: System.system_time(:second)})" | mount_body]
    else
      mount_body
    end
    
    Enum.join(Enum.reverse(mount_body), "\n    ")
  end
  
  defp generate_elixir_initial_assigns(config) do
    assigns = config.assigns
    |> Enum.map(fn {key, type} ->
      " |> assign(:#{key}, #{default_value_for_type(type)})"
    end)
    |> Enum.join("\n         ")
    
    schema_assigns = if config.schema && config.context do
      schema_lower = String.downcase(config.schema)
      """
       |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
               |> assign(:selected_#{schema_lower}, nil)
               |> assign(:changeset, nil)
      """
    else
      ""
    end
    
    modal_assigns = if config.modal do
      " |> assign(:show_modal, false)"
    else
      ""
    end
    
    table_assigns = if config.table do
      """
       |> assign(:sort_by, "id")
               |> assign(:sort_order, :asc)
               |> assign(:filter_text, "")
               |> assign(:current_page, 1)
               |> assign(:per_page, 10)
      """
    else
      ""
    end
    
    assigns <> schema_assigns <> modal_assigns <> table_assigns
  end
  
  defp generate_elixir_event_handlers(config) do
    handlers = []
    
    handlers = if :new in config.actions && config.schema do
      [generate_elixir_new_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if :edit in config.actions && config.schema do
      [generate_elixir_edit_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if :delete in config.actions && config.schema do
      [generate_elixir_delete_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if config.form && config.schema do
      [generate_elixir_save_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = if config.table do
      [
        generate_elixir_sort_handler(config),
        generate_elixir_filter_handler(config),
        generate_elixir_paginate_handler(config)
      ] ++ handlers
    else
      handlers
    end
    
    handlers = if config.modal do
      [generate_elixir_close_modal_handler(config) | handlers]
    else
      handlers
    end
    
    handlers = config.events
    |> Enum.map(fn event ->
      """
      @impl true
      def handle_event("#{event}", params, socket) do
        # TODO: Implement #{event} handler
        {:noreply, socket}
      end
      """
    end)
    |> Kernel.++(handlers)
    
    Enum.join(Enum.reverse(handlers), "\n  ")
  end
  
  defp generate_elixir_new_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    @impl true
    def handle_event("new_#{schema_lower}", _params, socket) do
      changeset = #{config.context}.change_#{schema_lower}(%#{config.schema}{})
      
      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:selected_#{schema_lower}, nil)
       #{if config.modal do
         "|> assign(:show_modal, true)"
       else
         ""
       end}}
    end
    """
  end
  
  defp generate_elixir_edit_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    @impl true
    def handle_event("edit_#{schema_lower}", %{"id" => id}, socket) do
      #{schema_lower} = #{config.context}.get_#{schema_lower}!(id)
      changeset = #{config.context}.change_#{schema_lower}(#{schema_lower})
      
      {:noreply,
       socket
       |> assign(:selected_#{schema_lower}, #{schema_lower})
       |> assign(:changeset, changeset)
       #{if config.modal do
         "|> assign(:show_modal, true)"
       else
         ""
       end}}
    end
    """
  end
  
  defp generate_elixir_delete_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    @impl true
    def handle_event("delete_#{schema_lower}", %{"id" => id}, socket) do
      #{schema_lower} = #{config.context}.get_#{schema_lower}!(id)
      {:ok, _} = #{config.context}.delete_#{schema_lower}(#{schema_lower})
      
      {:noreply,
       socket
       |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
       |> put_flash(:info, "#{config.schema} deleted successfully")}
    end
    """
  end
  
  defp generate_elixir_save_handler(config) do
    schema_lower = String.downcase(config.schema)
    """
    @impl true
    def handle_event("save", %{"#{schema_lower}" => #{schema_lower}_params}, socket) do
      save_#{schema_lower}(socket, socket.assigns.selected_#{schema_lower}, #{schema_lower}_params)
    end
    """
  end
  
  defp generate_elixir_sort_handler(_config) do
    """
    @impl true
    def handle_event("sort", %{"field" => field}, socket) do
      sort_order = if socket.assigns.sort_by == field do
        toggle_sort_order(socket.assigns.sort_order)
      else
        :asc
      end
      
      {:noreply,
       socket
       |> assign(:sort_by, field)
       |> assign(:sort_order, sort_order)
       |> apply_filters()}
    end
    """
  end
  
  defp generate_elixir_filter_handler(_config) do
    """
    @impl true
    def handle_event("filter", %{"filter" => filter_text}, socket) do
      {:noreply,
       socket
       |> assign(:filter_text, filter_text)
       |> assign(:current_page, 1)
       |> apply_filters()}
    end
    """
  end
  
  defp generate_elixir_paginate_handler(_config) do
    """
    @impl true
    def handle_event("paginate", %{"page" => page}, socket) do
      {:noreply,
       socket
       |> assign(:current_page, String.to_integer(page))
       |> apply_filters()}
    end
    """
  end
  
  defp generate_elixir_close_modal_handler(_config) do
    """
    @impl true
    def handle_event("close_modal", _params, socket) do
      {:noreply,
       socket
       |> assign(:show_modal, false)
       |> assign(:changeset, nil)
       |> assign(:selected_item, nil)}
    end
    """
  end
  
  defp generate_elixir_handle_info(config) do
    schema_lower = String.downcase(config.schema || "item")
    """
    @impl true
    def handle_info({:#{schema_lower}_created, #{schema_lower}}, socket) do
      {:noreply,
       socket
       |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
       |> put_flash(:info, "New #{config.schema || "item"} created")}
    end
    
    @impl true
    def handle_info({:#{schema_lower}_updated, #{schema_lower}}, socket) do
      {:noreply,
       socket
       |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
       |> put_flash(:info, "#{config.schema || "Item"} updated")}
    end
    
    @impl true
    def handle_info({:#{schema_lower}_deleted, #{schema_lower}}, socket) do
      {:noreply,
       socket
       |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
       |> put_flash(:info, "#{config.schema || "Item"} deleted")}
    end
    """
  end
  
  defp generate_elixir_render(config) do
    """
    @impl true
    def render(assigns) do
      ~H\"""
      <div class="#{String.downcase(config.schema || "container")}">
        <.header>
          #{config.schema || "LiveView"} Management
          <:actions>
            #{if :new in config.actions do
              """
              <.button phx-click="new_#{String.downcase(config.schema || "item")}">
                <.icon name="hero-plus" /> New #{config.schema || "Item"}
              </.button>
              """
            else
              ""
            end}
          </:actions>
        </.header>
        
        #{if config.table && config.schema do
          generate_elixir_table_template(config)
        else
          ""
        end}
        
        #{if config.modal && config.schema do
          generate_elixir_modal_template(config)
        else
          ""
        end}
      </div>
      \"""
    end
    """
  end
  
  defp generate_elixir_table_template(config) do
    schema_lower = String.downcase(config.schema)
    """
    <.table id="#{schema_lower}s" rows={@#{schema_lower}s}>
      <:col :let={#{schema_lower}} label="ID"><%= #{schema_lower}.id %></:col>
      <:col :let={#{schema_lower}} label="Name"><%= #{schema_lower}.name %></:col>
      <:action :let={#{schema_lower}}>
        <.link phx-click="edit_#{schema_lower}" phx-value-id={#{schema_lower}.id}>
          Edit
        </.link>
      </:action>
      <:action :let={#{schema_lower}}>
        <.link
          phx-click="delete_#{schema_lower}"
          phx-value-id={#{schema_lower}.id}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end
  
  defp generate_elixir_modal_template(config) do
    schema_lower = String.downcase(config.schema)
    """
    <.modal :if={@show_modal} id="#{schema_lower}-modal" show on_cancel={JS.push("close_modal")}>
      <.header>
        <%= if @selected_#{schema_lower}, do: "Edit", else: "New" %> #{config.schema}
      </.header>
      
      <.simple_form
        for={@changeset}
        id="#{schema_lower}-form"
        phx-submit="save"
      >
        <.input field={@changeset[:name]} type="text" label="Name" />
        
        <:actions>
          <.button phx-disable-with="Saving...">Save #{config.schema}</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
  
  defp generate_elixir_components(_config) do
    """
    # Function components can be added here
    defp data_table(assigns) do
      ~H\"""
      <div class="data-table">
        <%= render_slot(@inner_block) %>
      </div>
      \"""
    end
    """
  end
  
  defp generate_private_functions(config) do
    functions = []
    
    functions = if config.schema && config.context do
      [generate_save_function(config) | functions]
    else
      functions
    end
    
    functions = if config.table do
      [
        generate_apply_filters_function(config),
        generate_toggle_sort_function()
      ] ++ functions
    else
      functions
    end
    
    Enum.join(functions, "\n  ")
  end
  
  defp generate_save_function(config) do
    schema_lower = String.downcase(config.schema)
    """
    defp save_#{schema_lower}(socket, nil, #{schema_lower}_params) do
      case #{config.context}.create_#{schema_lower}(#{schema_lower}_params) do
        {:ok, #{schema_lower}} ->
          #{if config.pubsub do
            """
            Phoenix.PubSub.broadcast(
              #{Mix.Project.config()[:app] |> to_string() |> Macro.camelize()}.PubSub,
              "#{schema_lower}s",
              {:#{schema_lower}_created, #{schema_lower}}
            )
            """
          else
            ""
          end}
          
          {:noreply,
           socket
           |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
           |> assign(:changeset, nil)
           |> assign(:selected_#{schema_lower}, nil)
           #{if config.modal do
             "|> assign(:show_modal, false)"
           else
             ""
           end}
           |> put_flash(:info, "#{config.schema} created successfully")}
           
        {:error, changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    end
    
    defp save_#{schema_lower}(socket, #{schema_lower}, #{schema_lower}_params) do
      case #{config.context}.update_#{schema_lower}(#{schema_lower}, #{schema_lower}_params) do
        {:ok, #{schema_lower}} ->
          #{if config.pubsub do
            """
            Phoenix.PubSub.broadcast(
              #{Mix.Project.config()[:app] |> to_string() |> Macro.camelize()}.PubSub,
              "#{schema_lower}s",
              {:#{schema_lower}_updated, #{schema_lower}}
            )
            """
          else
            ""
          end}
          
          {:noreply,
           socket
           |> assign(:#{schema_lower}s, #{config.context}.list_#{schema_lower}s())
           |> assign(:changeset, nil)
           |> assign(:selected_#{schema_lower}, nil)
           #{if config.modal do
             "|> assign(:show_modal, false)"
           else
             ""
           end}
           |> put_flash(:info, "#{config.schema} updated successfully")}
           
        {:error, changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    end
    """
  end
  
  defp generate_apply_filters_function(config) do
    if config.schema && config.context do
      schema_lower = String.downcase(config.schema)
      """
      defp apply_filters(socket) do
        #{schema_lower}s = #{config.context}.list_#{schema_lower}s()
        
        # Apply text filter
        filtered = if socket.assigns.filter_text != "" do
          Enum.filter(#{schema_lower}s, fn #{schema_lower} ->
            String.contains?(
              String.downcase(#{schema_lower}.name || ""),
              String.downcase(socket.assigns.filter_text)
            )
          end)
        else
          #{schema_lower}s
        end
        
        # Apply sorting
        sorted = Enum.sort_by(filtered, & Map.get(&1, String.to_atom(socket.assigns.sort_by)), socket.assigns.sort_order)
        
        # Apply pagination
        start_index = (socket.assigns.current_page - 1) * socket.assigns.per_page
        paginated = Enum.slice(sorted, start_index, socket.assigns.per_page)
        
        assign(socket, :#{schema_lower}s, paginated)
      end
      """
    else
      """
      defp apply_filters(socket) do
        # Implement filtering logic here
        socket
      end
      """
    end
  end
  
  defp generate_toggle_sort_function() do
    """
    defp toggle_sort_order(:asc), do: :desc
    defp toggle_sort_order(:desc), do: :asc
    """
  end
  
  defp default_value_for_type(type) do
    case type do
      :string -> "\"\""
      :integer -> "0"
      :float -> "0.0"
      :boolean -> "false"
      :array -> "[]"
      :map -> "{}"
      _ -> "null"
    end
  end
end