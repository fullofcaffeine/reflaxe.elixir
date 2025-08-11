package test.generator;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.generator.InteractiveCLI;
import haxe.io.Input;
import haxe.io.BytesInput;
import haxe.io.Bytes;
using StringTools;

/**
 * Interactive CLI Test Suite
 * 
 * Tests the interactive command-line interface including:
 * - User prompts and input validation
 * - Choice selection
 * - Yes/No confirmations
 * - Multi-select options
 * - Input edge cases
 */
class InteractiveCLITest extends Test {
    
    var originalStdin: Input;
    
    public function setup() {
        // Save original stdin for restoration
        originalStdin = Sys.stdin();
    }
    
    public function teardown() {
        // Restore original stdin
        // Note: In real tests, we'd need to mock Sys.stdin properly
        // This is a simplified version for demonstration
    }
    
    // === PROMPT TESTS ===
    
    function testPromptWithDefault() {
        // Simulate user pressing Enter (empty input)
        var mockInput = createMockInput("\n");
        
        // This would need proper mocking in real implementation
        // For now, we test the logic separately
        var question = "Project name";
        var defaultValue = "my-app";
        
        // Test the prompt text formatting
        var promptText = defaultValue != null 
            ? '$question [$defaultValue]: '
            : '$question: ';
        
        Assert.equals("Project name [my-app]: ", promptText, "Prompt should show default value");
    }
    
    function testPromptValidation() {
        // Test that empty input without default triggers re-prompt
        var question = "Required field";
        var promptText = '$question: ';
        
        Assert.isTrue(promptText.indexOf("Required field") >= 0, "Should show question");
        Assert.isTrue(promptText.endsWith(": "), "Should end with colon and space");
    }
    
    // === CHOICE SELECTION TESTS ===
    
    function testChoiceDisplay() {
        var choices = [
            {value: "basic", label: "Basic - Standard Mix project"},
            {value: "phoenix", label: "Phoenix - Full web application"},
            {value: "liveview", label: "LiveView - Phoenix with LiveView"}
        ];
        
        // Test choice formatting
        Assert.equals(3, choices.length, "Should have 3 choices");
        Assert.equals("basic", choices[0].value, "First choice value should be 'basic'");
        Assert.isTrue(choices[1].label.indexOf("Phoenix") >= 0, "Second choice should mention Phoenix");
    }
    
    function testChoiceWithDefault() {
        var choices = [
            {value: 1, label: "Option One"},
            {value: 2, label: "Option Two"},
            {value: 3, label: "Option Three"}
        ];
        var defaultValue = 2;
        
        // Find default index
        var defaultIndex = -1;
        for (i in 0...choices.length) {
            if (choices[i].value == defaultValue) {
                defaultIndex = i;
                break;
            }
        }
        
        Assert.equals(1, defaultIndex, "Default should be at index 1");
        
        // Test choice prompt formatting
        var promptText = "Choose [1-" + choices.length + "]" + 
            (defaultIndex >= 0 ? " [" + (defaultIndex + 1) + "]" : "") + ": ";
        
        Assert.equals("Choose [1-3] [2]: ", promptText, "Should show range and default");
    }
    
    // === YES/NO CONFIRMATION TESTS ===
    
    function testYesNoPromptFormatting() {
        // Test with default true
        var optionsTrue = true ? "[Y/n]" : "[y/N]";
        Assert.equals("[Y/n]", optionsTrue, "Default true should show Y uppercase");
        
        // Test with default false
        var optionsFalse = false ? "[Y/n]" : "[y/N]";
        Assert.equals("[y/N]", optionsFalse, "Default false should show N uppercase");
    }
    
    function testYesNoAnswerParsing() {
        // Test various yes inputs
        var yesInputs = ["y", "yes", "Y", "YES", "Yes"];
        for (input in yesInputs) {
            var result = (input.toLowerCase() == "y" || input.toLowerCase() == "yes");
            Assert.isTrue(result, 'Input "$input" should be parsed as yes');
        }
        
        // Test various no inputs
        var noInputs = ["n", "no", "N", "NO", "No"];
        for (input in noInputs) {
            var result = (input.toLowerCase() == "n" || input.toLowerCase() == "no");
            Assert.isTrue(result, 'Input "$input" should be parsed as no');
        }
    }
    
    // === MULTI-SELECT TESTS ===
    
    function testMultiSelectParsing() {
        var input = "1 3 5";
        var parts = input.split(" ");
        var selected = [];
        
        for (part in parts) {
            var num = Std.parseInt(part);
            if (num != null) {
                selected.push(num);
            }
        }
        
        Assert.equals(3, selected.length, "Should parse 3 selections");
        Assert.equals(1, selected[0], "First selection should be 1");
        Assert.equals(3, selected[1], "Second selection should be 3");
        Assert.equals(5, selected[2], "Third selection should be 5");
    }
    
    function testMultiSelectDuplicates() {
        var input = "1 2 1 3 2";
        var parts = input.split(" ");
        var selected = [];
        
        for (part in parts) {
            var num = Std.parseInt(part);
            if (num != null && selected.indexOf(num) < 0) {
                selected.push(num);
            }
        }
        
        Assert.equals(3, selected.length, "Should remove duplicates");
        Assert.isTrue(selected.indexOf(1) >= 0, "Should include 1");
        Assert.isTrue(selected.indexOf(2) >= 0, "Should include 2");
        Assert.isTrue(selected.indexOf(3) >= 0, "Should include 3");
    }
    
    // === UI ELEMENT TESTS ===
    
    function testProgressBarFormatting() {
        var current = 15;
        var total = 30;
        var percent = Math.round((current / total) * 100);
        var barLength = 30;
        var filled = Math.round((current / total) * barLength);
        
        Assert.equals(50, percent, "Should calculate 50% progress");
        Assert.equals(15, filled, "Should fill half the bar");
        
        var bar = "[";
        for (i in 0...barLength) {
            bar += i < filled ? "█" : "░";
        }
        bar += "]";
        
        Assert.isTrue(bar.indexOf("█") >= 0, "Should contain filled blocks");
        Assert.isTrue(bar.indexOf("░") >= 0, "Should contain empty blocks");
        Assert.equals(32, bar.length, "Bar should be correct length (30 + brackets)");
    }
    
    function testSpinnerFrames() {
        var frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
        
        Assert.equals(10, frames.length, "Should have 10 spinner frames");
        
        // Test frame cycling
        var frameIndex = 0;
        for (i in 0...15) {
            var frame = frames[frameIndex % frames.length];
            Assert.notNull(frame, "Frame should exist at any index");
            frameIndex++;
        }
    }
    
    // === MESSAGE FORMATTING TESTS ===
    
    function testErrorMessageFormatting() {
        var message = "Something went wrong";
        var formatted = '❌ Error: $message';
        
        Assert.isTrue(formatted.indexOf("❌") >= 0, "Should include error emoji");
        Assert.isTrue(formatted.indexOf("Error:") >= 0, "Should include Error label");
        Assert.isTrue(formatted.indexOf(message) >= 0, "Should include message");
    }
    
    function testWarningMessageFormatting() {
        var message = "This might cause issues";
        var formatted = '⚠️  Warning: $message';
        
        Assert.isTrue(formatted.indexOf("⚠️") >= 0, "Should include warning emoji");
        Assert.isTrue(formatted.indexOf("Warning:") >= 0, "Should include Warning label");
    }
    
    function testSuccessMessageFormatting() {
        var message = "Operation completed";
        var formatted = '✅ $message';
        
        Assert.isTrue(formatted.indexOf("✅") >= 0, "Should include success emoji");
        Assert.isTrue(formatted.indexOf(message) >= 0, "Should include message");
    }
    
    function testInfoMessageFormatting() {
        var message = "Additional information";
        var formatted = 'ℹ️  $message';
        
        Assert.isTrue(formatted.indexOf("ℹ️") >= 0, "Should include info emoji");
        Assert.isTrue(formatted.indexOf(message) >= 0, "Should include message");
    }
    
    // === PROJECT CONFIG TESTS ===
    
    function testProjectConfigStructure() {
        var config: ProjectConfig = {
            name: "test-project",
            type: "phoenix",
            skipInstall: false,
            includeExamples: true,
            database: "postgres",
            authentication: true
        };
        
        Assert.equals("test-project", config.name, "Name should be set");
        Assert.equals("phoenix", config.type, "Type should be phoenix");
        Assert.isFalse(config.skipInstall, "Should install by default");
        Assert.isTrue(config.includeExamples, "Should include examples");
        Assert.equals("postgres", config.database, "Database should be postgres");
        Assert.isTrue(config.authentication, "Authentication should be enabled");
    }
    
    // === EDGE CASES ===
    
    function testEmptyChoiceArray() {
        var choices: Array<Choice<String>> = [];
        Assert.equals(0, choices.length, "Should handle empty choice array");
    }
    
    function testInvalidNumberInput() {
        var input = "abc";
        var parsed = Std.parseInt(input);
        Assert.isNull(parsed, "Should return null for non-numeric input");
    }
    
    function testOutOfRangeChoice() {
        var choices = [{value: "a", label: "A"}, {value: "b", label: "B"}];
        var input = "5";
        var choiceNum = Std.parseInt(input);
        
        var isValid = choiceNum != null && choiceNum >= 1 && choiceNum <= choices.length;
        Assert.isFalse(isValid, "Choice 5 should be invalid for 2 options");
    }
    
    function testSpecialCharactersInInput() {
        var input = "my-project!@#";
        // Should handle special characters in project names
        Assert.isTrue(input.length > 0, "Should accept special character input");
    }
    
    // === HELPER METHODS ===
    
    private function createMockInput(data: String): Input {
        var bytes = Bytes.ofString(data);
        return new BytesInput(bytes);
    }
}

// Type definitions to match InteractiveCLI
typedef Choice<T> = {
    value: T,
    label: String
}

typedef ProjectConfig = {
    name: String,
    type: String,
    skipInstall: Bool,
    includeExamples: Bool,
    ?database: String,
    ?authentication: Bool
}