defmodule Mix.Tasks.Haxe.Gen.Project do
  @moduledoc """
  Mix task for adding Reflaxe.Elixir support to existing Elixir projects.

  This task sets up the necessary directory structure, configuration files,
  and build pipeline to enable Haxe compilation within an existing Elixir project.
  It's the Mix complement to the Haxe-based project generator.

  ## Examples

      mix haxe.gen.project
      mix haxe.gen.project --basic-modules
      mix haxe.gen.project --phoenix
      mix haxe.gen.project --skip-examples

  ## Options

    * `--basic-modules` - Include basic utility modules (StringUtils, MathHelper)
    * `--phoenix` - Add Phoenix-specific configuration and examples
    * `--skip-examples` - Don't generate example Haxe files
    * `--skip-npm` - Don't create package.json or install npm dependencies
    * `--haxe-dir` - Directory for Haxe source files (default: "src_haxe")
    * `--output-dir` - Directory for generated Elixir files (default: "lib/<app>_hx")
    * `--force` - Overwrite existing files without confirmation

  """
  use Mix.Task

  @shortdoc "Adds Reflaxe.Elixir support to existing Elixir project"
  @requirements ["app.config"]

  @doc """
  Entry point for the Mix task
  """
  def run(args) do
    {opts, [], _} =
      OptionParser.parse(args,
        switches: [
          basic_modules: :boolean,
          phoenix: :boolean,
          skip_examples: :boolean,
          skip_npm: :boolean,
          haxe_dir: :string,
          output_dir: :string,
          force: :boolean
        ]
      )

    Mix.shell().info("Adding Reflaxe.Elixir support to existing project...")

    app_name = get_app_name()
    module_name = get_module_name()
    haxe_namespace = "#{app_name}_hx"
    elixir_namespace = "#{module_name}Hx"
    default_output_dir = Path.join(["lib", haxe_namespace])

    project_config = %{
      app_name: app_name,
      module_name: module_name,
      haxe_namespace: haxe_namespace,
      elixir_namespace: elixir_namespace,
      haxe_dir: Keyword.get(opts, :haxe_dir, "src_haxe"),
      output_dir: Keyword.get(opts, :output_dir, default_output_dir),
      basic_modules: Keyword.get(opts, :basic_modules, false),
      phoenix: Keyword.get(opts, :phoenix, false),
      skip_examples: Keyword.get(opts, :skip_examples, false),
      skip_npm: Keyword.get(opts, :skip_npm, false),
      force: Keyword.get(opts, :force, false)
    }

    setup_project(project_config)
  end

  # Main setup workflow
  defp setup_project(config) do
    # 1. Create directory structure
    create_directories(config)

    # 2. Create Haxe build configuration
    create_build_config(config)

    # 2b. Create .haxerc for lix-managed toolchain (if missing)
    create_haxerc(config)

    # 3. Create package.json for npm dependencies (if not skipped)
    unless config.skip_npm do
      create_package_json(config)
    end

    # 4. Update mix.exs with Haxe compiler
    update_mix_exs(config)

    # 5. Create example modules (if not skipped)
    unless config.skip_examples do
      create_example_modules(config)
    end

    # 6. Create VS Code configuration
    create_vscode_config(config)

    # 7. Update .gitignore
    update_gitignore(config)

    # 8. Display next steps
    display_next_steps(config)

    Mix.shell().info("✅ Successfully added Reflaxe.Elixir support!")
    :ok
  end

  # Create necessary directories
  defp create_directories(config) do
    haxe_base = Path.join([config.haxe_dir, config.haxe_namespace])

    base_directories = [
      config.haxe_dir,
      config.output_dir,
      haxe_base,
      Path.join([haxe_base, "utils"]),
      Path.join([haxe_base, "services"]),
      ".vscode"
    ]

    all_directories =
      if config.phoenix do
        base_directories ++
          [
            Path.join([haxe_base, "live"]),
            Path.join([haxe_base, "controllers"])
          ]
      else
        base_directories
      end

    Enum.each(all_directories, fn dir ->
      File.mkdir_p!(dir)
      Mix.shell().info("Created directory: #{dir}")
    end)
  end

  # Create build.hxml configuration file
  defp create_build_config(config) do
    build_content = build_hxml_content(config)

    write_file_with_confirmation("build.hxml", build_content, config.force)
    Mix.shell().info("Created Haxe build configuration: build.hxml")
  end

  defp create_haxerc(config) do
    haxerc_content =
      Jason.encode!(%{version: "4.3.7", resolveLibs: "scoped"}, pretty: true) <> "\n"

    write_file_with_confirmation(".haxerc", haxerc_content, config.force)
    Mix.shell().info("Created .haxerc for lix-managed Haxe toolchain")
  end

  # Generate build.hxml content
  defp build_hxml_content(config) do
    main_module = "#{config.haxe_namespace}.Main"

    modules_section =
      cond do
        config.skip_examples ->
          """
          # Modules to compile
          #
          # Add your own Haxe modules here (one per line), e.g.:
          # MyApp.MyContext
          # live.DashboardLive
          """

        true ->
          modules =
            [main_module]
            |> maybe_append_modules(config.basic_modules, [
              "#{config.haxe_namespace}.utils.StringUtils",
              "#{config.haxe_namespace}.utils.MathHelper"
            ])
            |> maybe_append_modules(config.phoenix, ["#{config.haxe_namespace}.live.AppLive"])

          Enum.join(modules, "\n") <> "\n"
      end

    """
    # Reflaxe.Elixir Build Configuration
    # Generated by mix haxe.gen.project
    #
    # Notes
    # - `-lib reflaxe.elixir` initializes the compiler (via haxe_libraries/reflaxe.elixir.hxml).
    # - Add the modules you want to compile at the bottom (one per line).

    # Libraries
    -lib reflaxe.elixir

    # Source directories
    -cp #{config.haxe_dir}

    # Output directory for generated .ex files
    -D elixir_output=#{config.output_dir}

    # Required for Reflaxe targets
    -D reflaxe_runtime

    # Elixir is not a UTF-16 platform
    -D no-utf16

    # Application module prefix (prevents collisions with Elixir built-ins like `Application`)
    -D app_name=#{config.elixir_namespace}

    # Enable dead code elimination to remove unused functions and reduce output noise
    -dce full

    #{if config.phoenix, do: "# Convert HXX render strings to `~H` sigils (recommended for LiveView)\n-D hxx_string_to_sigil\n", else: ""}
    #{modules_section}
    """
  end

  # Create package.json for npm dependencies
  defp create_package_json(config) do
    package_content = package_json_content(config)

    write_file_with_confirmation("package.json", package_content, config.force)
    Mix.shell().info("Created package.json with npm dependencies")
  end

  # Generate package.json content
  defp package_json_content(config) do
    Jason.encode!(
      %{
        name: to_string(config.app_name),
        version: "0.1.0",
        description: "Elixir project with Reflaxe.Elixir support",
        scripts: %{
          "setup:haxe": "npx lix download",
          compile: "npx haxe build.hxml",
          watch: "npx nodemon --watch #{config.haxe_dir} --ext hx --exec \"npx haxe build.hxml\"",
          test: "mix test"
        },
        devDependencies: %{
          lix: "^15.12.4",
          nodemon: "^3.0.0"
        }
      },
      pretty: true
    )
  end

  # Update mix.exs to include Haxe compiler
  defp update_mix_exs(config) do
    mix_exs_path = "mix.exs"

    unless File.exists?(mix_exs_path) do
      Mix.shell().error("mix.exs not found - this doesn't appear to be an Elixir project")
      System.halt(1)
    end

    current_content = File.read!(mix_exs_path)

    has_haxe_compiler? = Regex.match?(~r/compilers:\s*\[([^\]]*):haxe/m, current_content)
    has_haxe_config? = Regex.match?(~r/\bhaxe:\s*\[/m, current_content)

    # Check if already has Haxe compiler and config
    if has_haxe_compiler? && has_haxe_config? do
      Mix.shell().info("mix.exs already includes Haxe compiler configuration")
    else
      updated_content =
        current_content
        |> maybe_add_haxe_compiler_to_mix_exs(has_haxe_compiler?)
        |> maybe_add_haxe_config_to_mix_exs(config, has_haxe_config?)

      if config.force || confirm_overwrite("mix.exs") do
        File.write!(mix_exs_path, updated_content)
        Mix.shell().info("✅ Updated mix.exs with Haxe compiler configuration")
      else
        Mix.shell().info("Skipped updating mix.exs")
        Mix.shell().info("To manually add Haxe support, add this to your mix.exs project config:")
        Mix.shell().info("  compilers: [:haxe] ++ Mix.compilers()")
      end
    end
  end

  # Add Haxe compiler to mix.exs
  defp maybe_add_haxe_compiler_to_mix_exs(content, true), do: content

  defp maybe_add_haxe_compiler_to_mix_exs(content, false) do
    # Look for the project function and add compilers configuration
    content
    |> String.replace(
      ~r/(def project do\s*\[)/m,
      "\\1\n      compilers: [:haxe] ++ Mix.compilers(),"
    )
  end

  defp maybe_add_haxe_config_to_mix_exs(content, _config, true), do: content

  defp maybe_add_haxe_config_to_mix_exs(content, config, false) do
    haxe_config = """
          haxe: [
            hxml_file: "build.hxml",
            source_dir: "#{config.haxe_dir}",
            target_dir: "#{config.output_dir}",
            watch: Mix.env() == :dev
          ],
    """

    if Regex.match?(~r/compilers:\s*[^\n,]+,/m, content) do
      Regex.replace(~r/(compilers:\s*[^\n,]+,)/m, content, "\\1\n" <> haxe_config)
    else
      String.replace(content, ~r/(def project do\s*\[)/m, "\\1\n" <> haxe_config)
    end
  end

  defp maybe_append_modules(modules, false, _to_append), do: modules
  defp maybe_append_modules(modules, true, to_append), do: modules ++ to_append

  # Create example modules
  defp create_example_modules(config) do
    haxe_base = Path.join([config.haxe_dir, config.haxe_namespace])

    # Main.hx entry point
    main_content = main_hx_content(config)
    write_file_with_confirmation(Path.join([haxe_base, "Main.hx"]), main_content, config.force)

    if config.basic_modules do
      # StringUtils utility
      string_utils_content = string_utils_content(config)

      write_file_with_confirmation(
        Path.join([haxe_base, "utils", "StringUtils.hx"]),
        string_utils_content,
        config.force
      )

      # MathHelper utility
      math_helper_content = math_helper_content(config)

      write_file_with_confirmation(
        Path.join([haxe_base, "utils", "MathHelper.hx"]),
        math_helper_content,
        config.force
      )
    end

    if config.phoenix do
      # Phoenix LiveView example
      live_example_content = live_example_content(config)

      write_file_with_confirmation(
        Path.join([haxe_base, "live", "AppLive.hx"]),
        live_example_content,
        config.force
      )
    end

    Mix.shell().info("Created example Haxe modules")
  end

  # Generate Main.hx content
  defp main_hx_content(config) do
    """
    package #{config.haxe_namespace};

    /**
     * Main entry point for Reflaxe.Elixir compilation
     * Generated by mix haxe.gen.project
     */
    @:module
    class Main {
        public static function main(): Void {
            // Entry point for Haxe compilation
            trace("#{config.elixir_namespace} - Reflaxe.Elixir compilation successful!");
        }
        
        public static function hello(name: String): String {
            return 'Hello, $name! Welcome to Reflaxe.Elixir!';
        }
    }
    """
  end

  # Generate StringUtils content
  defp string_utils_content(config) do
    """
    package #{config.haxe_namespace}.utils;

    /**
     * String utility functions
     * Generated example module
     */
    @:module
    class StringUtils {
        public static function capitalize(str: String): String {
            if (str.length == 0) return str;
            return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
        }
        
        public static function reverse(str: String): String {
            var chars = str.split("");
            chars.reverse();
            return chars.join("");
        }
        
        public static function slugify(str: String): String {
            return str.toLowerCase()
                     .split(" ")
                     .join("-")
                     .split("_")
                     .join("-");
        }
    }
    """
  end

  # Generate MathHelper content
  defp math_helper_content(config) do
    """
    package #{config.haxe_namespace}.utils;

    /**
     * Mathematical utility functions  
     * Generated example module
     */
    @:module
    class MathHelper {
        public static function clamp(value: Float, min: Float, max: Float): Float {
            if (value < min) return min;
            if (value > max) return max;
            return value;
        }
        
        public static function lerp(a: Float, b: Float, t: Float): Float {
            return a + (b - a) * t;
        }
        
        public static function isPrime(n: Int): Bool {
            if (n <= 1) return false;
            if (n <= 3) return true;
            if (n % 2 == 0 || n % 3 == 0) return false;
            
            var i = 5;
            while (i * i <= n) {
                if (n % i == 0 || n % (i + 2) == 0) return false;
                i += 6;
            }
            return true;
        }
    }
    """
  end

  # Generate LiveView example content
  defp live_example_content(config) do
    """
    package #{config.haxe_namespace}.live;

    import phoenix.Phoenix.LiveView;
    import phoenix.Phoenix.MountParams;
    import phoenix.Phoenix.Session;
    import phoenix.Phoenix.Socket;
    import phoenix.Phoenix.MountResult;
    import phoenix.Phoenix.EventParams;
    import phoenix.Phoenix.HandleEventResult;

    import HXX.*;

    private typedef AppLiveAssigns = {
        count: Int,
    }

    /**
     * Phoenix LiveView: AppLive
     *
     * Generated by `mix haxe.gen.project --phoenix`. This is Haxe-authored and compiles to
     * idiomatic Phoenix LiveView callbacks (`mount/3`, `handle_event/3`, `render/1`).
     */
    @:native("#{config.module_name}Web.AppLive")
    @:liveview
    class AppLive {
        public static function mount(_params: MountParams, _session: Session, socket: Socket<AppLiveAssigns>): MountResult<AppLiveAssigns> {
            var assigns: AppLiveAssigns = {
                count: 0,
            };

            return Ok(LiveView.assignMultiple(socket, assigns));
        }

        public static function handle_event(event: String, _params: EventParams, socket: Socket<AppLiveAssigns>): HandleEventResult<AppLiveAssigns> {
            return switch (event) {
                case "increment":
                    var updated = LiveView.assignMultiple(socket, {count: socket.assigns.count + 1});
                    NoReply(updated);

                case "decrement":
                    var updated = LiveView.assignMultiple(socket, {count: socket.assigns.count - 1});
                    NoReply(updated);

                default:
                    NoReply(socket);
            };
        }

        public static function render(assigns: AppLiveAssigns): String {
            return hxx('
                <div class="p-6">
                    <h1 class="text-2xl font-semibold">#{config.module_name} Counter</h1>
                    <p class="mt-2">Count: \#{@count}</p>
                    <div class="mt-4 flex gap-2">
                        <button phx-click="decrement" class="px-3 py-2 border rounded">-</button>
                        <button phx-click="increment" class="px-3 py-2 border rounded">+</button>
                    </div>
                </div>
            ');
        }
    }
    """
  end

  # Create VS Code configuration
  defp create_vscode_config(config) do
    # settings.json
    settings_content = vscode_settings_content()
    write_file_with_confirmation(".vscode/settings.json", settings_content, config.force)

    # extensions.json
    extensions_content = vscode_extensions_content()
    write_file_with_confirmation(".vscode/extensions.json", extensions_content, config.force)

    Mix.shell().info("Created VS Code configuration")
  end

  # Generate VS Code settings.json
  defp vscode_settings_content() do
    Jason.encode!(
      %{
        "editor.formatOnSave" => true,
        "files.exclude" => %{
          "**/_build" => true,
          "**/deps" => true,
          "**/node_modules" => true
        },
        "[haxe]" => %{
          "editor.insertSpaces" => false
        },
        "[elixir]" => %{
          "editor.insertSpaces" => true,
          "editor.tabSize" => 2
        }
      },
      pretty: true
    )
  end

  # Generate VS Code extensions.json
  defp vscode_extensions_content() do
    Jason.encode!(
      %{
        recommendations: [
          "vshaxe.haxe-extension-pack",
          "jakebecker.elixir-ls",
          "phoenixframework.phoenix"
        ]
      },
      pretty: true
    )
  end

  # Update .gitignore to exclude generated files
  defp update_gitignore(config) do
    gitignore_additions = [
      "",
      "# Reflaxe.Elixir generated files",
      "#{config.output_dir}/",
      "node_modules/",
      "package-lock.json",
      "*.hxml.cache",
      ".haxe_cache/",
      ""
    ]

    if File.exists?(".gitignore") do
      current_content = File.read!(".gitignore")

      # Check if already contains our additions
      unless String.contains?(current_content, "Reflaxe.Elixir generated files") do
        updated_content = current_content <> Enum.join(gitignore_additions, "\n")
        File.write!(".gitignore", updated_content)
        Mix.shell().info("Updated .gitignore with Reflaxe.Elixir exclusions")
      end
    else
      File.write!(".gitignore", Enum.join(gitignore_additions, "\n"))
      Mix.shell().info("Created .gitignore with Reflaxe.Elixir exclusions")
    end
  end

  # Display next steps to the user
  defp display_next_steps(config) do
    Mix.shell().info("")
    Mix.shell().info("🎉 Reflaxe.Elixir setup complete!")
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  1. Install Reflaxe.Elixir (Haxe library):")
    Mix.shell().info("     npx lix scope create   # if you don't already have a lix scope")
    Mix.shell().info("     npx lix install github:fullofcaffeine/reflaxe.elixir")
    Mix.shell().info("     npm run setup:haxe")
    Mix.shell().info("")

    unless config.skip_npm do
      Mix.shell().info("  2. Install npm dependencies:")
      Mix.shell().info("     npm install")
      Mix.shell().info("")
    end

    Mix.shell().info("  3. Compile your first Haxe code:")
    Mix.shell().info("     npm run compile")
    Mix.shell().info("     # or: npx haxe build.hxml")
    Mix.shell().info("")
    Mix.shell().info("  4. Start development with file watching:")
    Mix.shell().info("     npm run watch")
    Mix.shell().info("")
    Mix.shell().info("  5. Test your generated Elixir code:")
    Mix.shell().info("     mix test")
    Mix.shell().info("")
    Mix.shell().info("📖 Docs:")
    Mix.shell().info("  https://github.com/fullofcaffeine/reflaxe.elixir/tree/main/docs")
    Mix.shell().info("")
  end

  # Helper functions

  defp get_app_name() do
    Mix.Project.config()[:app] || :my_app
  end

  defp get_module_name() do
    get_app_name() |> to_string() |> Macro.camelize()
  end

  defp write_file_with_confirmation(path, content, force) do
    if File.exists?(path) && !force do
      if confirm_overwrite(path) do
        File.write!(path, content)
      else
        Mix.shell().info("Skipped: #{path}")
      end
    else
      File.write!(path, content)
    end
  end

  defp confirm_overwrite(path) do
    Mix.shell().yes?("File #{path} already exists. Overwrite?")
  end
end
