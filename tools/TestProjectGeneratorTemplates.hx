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

        Sys.println("OK: ProjectGenerator add-to-existing scaffold");
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
