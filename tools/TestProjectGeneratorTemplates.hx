package tools;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import reflaxe.elixir.generator.ProjectGenerator;

/**
 * Minimal, bounded sanity check for the Haxe-based project generator.
 *
 * This is intentionally not a snapshot test: it validates that the generator can
 * scaffold "add-to-existing" projects without crashing and produces the expected
 * key files.
 */
class TestProjectGeneratorTemplates {
    public static function main(): Void {
        var root = Path.normalize(Path.join([Sys.getCwd(), "tmp", "generator-tests"]));
        mkdirp(root);

        var runDir = Path.join([root, "run-" + Std.string(Date.now().getTime())]);
        mkdirp(runDir);

        File.saveContent(Path.join([runDir, "mix.exs"]), minimalMixExs());

        var generator = new ProjectGenerator();
        generator.generate({
            name: "demo",
            type: "add-to-existing",
            skipInstall: true,
            verbose: false,
            vscode: false,
            workingDir: runDir
        });

        assertExists(Path.join([runDir, "build.hxml"]), "build.hxml was created");
        assertExists(Path.join([runDir, "package.json"]), "package.json was created");
        assertExists(Path.join([runDir, ".haxerc"]), ".haxerc was created");
        assertExists(Path.join([runDir, "AGENTS.md"]), "AGENTS.md was created");
        assertExists(Path.join([runDir, "src_haxe", "demo_hx", "Main.hx"]), "src_haxe/demo_hx/Main.hx was created");

        var mixExs = File.getContent(Path.join([runDir, "mix.exs"]));
        assertContains(mixExs, "compilers: [:haxe]", "mix.exs includes :haxe compiler");
        assertContains(mixExs, "haxe: [", "mix.exs includes haxe config block");

        var buildHxml = File.getContent(Path.join([runDir, "build.hxml"]));
        assertContains(buildHxml, "-lib reflaxe.elixir", "build.hxml includes reflaxe.elixir lib");
        assertContains(buildHxml, "-D elixir_output=lib/demo_hx", "build.hxml uses an isolated elixir_output dir");
        assertContains(buildHxml, "-D reflaxe_runtime", "build.hxml includes reflaxe_runtime define");
        assertContains(buildHxml, "-D no-utf16", "build.hxml includes no-utf16 define");
        assertContains(buildHxml, "-D app_name=DemoHx", "build.hxml includes app_name define");
        assertContains(buildHxml, "-dce full", "build.hxml enables dead code elimination");
        assertContains(buildHxml, "--main demo_hx.Main", "build.hxml sets a stable --main");
        assertNotContains(buildHxml, "CompilerInit.Start()", "build.hxml does not duplicate the bootstrap macro");

        assertMixTaskScaffold(root);

        Sys.println("OK: ProjectGenerator + Mix.Tasks.Haxe.Gen.Project scaffolds");
        rmrf(runDir);
    }

    private static function assertMixTaskScaffold(root: String): Void {
        var runDir = Path.join([root, "mix-task-" + Std.string(Date.now().getTime())]);
        mkdirp(runDir);

        File.saveContent(Path.join([runDir, "mix.exs"]), minimalMixExs());

        var elixirCode = 'Mix.Project.in_project(:demo, "${runDir}", fn _ -> Mix.Tasks.Haxe.Gen.Project.run(["--phoenix", "--basic-modules", "--force"]) end)';
        var exitCode = Sys.command("mix", ["run", "-e", elixirCode]);
        if (exitCode != 0) {
            Sys.println("FAIL: mix run -e scaffold failed (exit: " + exitCode + ")");
            Sys.exit(1);
        }

        assertExists(Path.join([runDir, "build.hxml"]), "mix task created build.hxml");
        assertExists(Path.join([runDir, "package.json"]), "mix task created package.json");
        assertExists(Path.join([runDir, "src_haxe", "demo_hx", "Main.hx"]), "mix task created src_haxe/demo_hx/Main.hx");
        assertExists(Path.join([runDir, "src_haxe", "demo_hx", "utils", "StringUtils.hx"]), "mix task created utils/StringUtils.hx");
        assertExists(Path.join([runDir, "src_haxe", "demo_hx", "live", "AppLive.hx"]), "mix task created live/AppLive.hx");

        var mixExs = File.getContent(Path.join([runDir, "mix.exs"]));
        assertContains(mixExs, "compilers: [:haxe]", "mix task updated mix.exs compilers");
        assertContains(mixExs, "haxe: [", "mix task added haxe config to mix.exs");

        var buildHxml = File.getContent(Path.join([runDir, "build.hxml"]));
        assertContains(buildHxml, "-lib reflaxe.elixir", "mix task build.hxml includes reflaxe.elixir lib");
        assertContains(buildHxml, "-D elixir_output=lib/demo_hx", "mix task build.hxml defaults to isolated output dir");
        assertContains(buildHxml, "-D app_name=DemoHx", "mix task build.hxml uses an isolated app_name prefix");
        assertContains(buildHxml, "-D no-utf16", "mix task build.hxml includes no-utf16");
        assertContains(buildHxml, "-D reflaxe_runtime", "mix task build.hxml includes reflaxe_runtime");
        assertContains(buildHxml, "-dce full", "mix task build.hxml enables dead code elimination");
        assertContains(buildHxml, "-D hxx_string_to_sigil", "mix task build.hxml includes hxx_string_to_sigil for Phoenix");
        assertContains(buildHxml, "demo_hx.Main", "mix task build.hxml compiles demo_hx.Main");
        assertContains(buildHxml, "demo_hx.live.AppLive", "mix task build.hxml compiles demo_hx.live.AppLive");

        rmrf(runDir);
    }

    private static function minimalMixExs(): String {
        return '
defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
';
    }

    private static function assertExists(path: String, message: String): Void {
        if (!FileSystem.exists(path)) {
            Sys.println("FAIL: " + message + " (missing: " + path + ")");
            Sys.exit(1);
        }
    }

    private static function assertContains(haystack: String, needle: String, message: String): Void {
        if (haystack.indexOf(needle) == -1) {
            Sys.println("FAIL: " + message + " (missing: " + needle + ")");
            Sys.exit(1);
        }
    }

    private static function assertNotContains(haystack: String, needle: String, message: String): Void {
        if (haystack.indexOf(needle) != -1) {
            Sys.println("FAIL: " + message + " (unexpected: " + needle + ")");
            Sys.exit(1);
        }
    }

    private static function mkdirp(path: String): Void {
        var normalizedPath = Path.normalize(path);
        var parts = normalizedPath.split("/");
        var current = StringTools.startsWith(normalizedPath, "/") ? "/" : "";

        for (part in parts) {
            if (part == "" || part == ".") continue;
            current = (current == "" || current == "/") ? current + part : Path.join([current, part]);
            if (!FileSystem.exists(current)) {
                FileSystem.createDirectory(current);
            }
        }
    }

    private static function rmrf(path: String): Void {
        if (!FileSystem.exists(path)) return;

        if (FileSystem.isDirectory(path)) {
            for (entry in FileSystem.readDirectory(path)) {
                rmrf(Path.join([path, entry]));
            }
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }
}
