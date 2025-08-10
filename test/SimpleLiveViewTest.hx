package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.LiveViewCompiler;

using StringTools;

/**
 * Modern Simple LiveView Test Suite with Core Functionality Focus - Migrated to utest
 * 
 * Tests essential LiveView compilation functionality with simplified approach,
 * complementing the comprehensive LiveViewTest.hx with basic functionality
 * validation and compatibility testing.
 * 
 * Migration patterns applied:
 * - @:asserts class → extends Test
 * - asserts.assert() → Assert.isTrue()
 * - return asserts.done() → (removed)
 * - @:describe("name") → function testName() with descriptive names
 * - All test logic preserved exactly as in original
 */
class SimpleLiveViewTest extends Test {
    
    function testLiveViewClassDetection() {
        Assert.isTrue(LiveViewCompiler.isLiveViewClass("TestLiveView"), "Should detect TestLiveView");
        Assert.isTrue(LiveViewCompiler.isLiveViewClass("UserLiveView"), "Should detect UserLiveView");
        Assert.isTrue(!LiveViewCompiler.isLiveViewClass("RegularClass"), "Should not detect regular class");
    }
    
    function testSocketTypeGeneration() {
        var socketType = LiveViewCompiler.generateSocketType();
        Assert.isTrue(socketType.contains("Phoenix.LiveView.Socket"), "Should reference Phoenix Socket");
        Assert.isTrue(socketType.contains("assigns"), "Should include assigns");
    }
    
    function testMountFunctionCompilation() {
        var mountFn = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        Assert.isTrue(mountFn.contains("def mount"), "Should generate mount function");
        Assert.isTrue(mountFn.contains("params, session, socket"), "Should have correct parameters");
        Assert.isTrue(mountFn.contains("{:ok, socket}"), "Should return {:ok, socket} tuple");
    }
    
    function testEventHandlerCompilation() {
        var eventFn = LiveViewCompiler.compileHandleEvent(
            "increment",
            "params, socket", 
            "counter = socket.assigns.counter + 1; socket = assign(socket, \"counter\", counter); return {noreply: socket};"
        );
        
        Assert.isTrue(eventFn.contains("def handle_event"), "Should generate handle_event");
        Assert.isTrue(eventFn.contains("\"increment\""), "Should include event name");
        Assert.isTrue(eventFn.contains("{:noreply, socket}"), "Should return noreply tuple");
    }
    
    function testAssignCompilation() {
        var assign = LiveViewCompiler.compileAssign("socket", "counter", "0");
        Assert.isTrue(assign.contains("assign(socket"), "Should call assign function");
        Assert.isTrue(assign.contains(":counter"), "Should use atom key");
        Assert.isTrue(assign.contains("0"), "Should include value");
    }
    
    function testModuleBoilerplate() {
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        Assert.isTrue(boilerplate.contains("defmodule TestLiveView"), "Should create module");
        Assert.isTrue(boilerplate.contains("use Phoenix.LiveView"), "Should use LiveView");
        Assert.isTrue(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
    }
    
    function testCompleteModuleGeneration() {
        var module = LiveViewCompiler.compileToLiveView("TestLiveView", "  def test, do: :ok");
        Assert.isTrue(module.contains("defmodule TestLiveView"), "Should have module declaration");
        Assert.isTrue(module.contains("use Phoenix.LiveView"), "Should use LiveView");
        Assert.isTrue(module.contains("def test, do: :ok"), "Should include custom content");
        Assert.isTrue(module.contains("end"), "Should close module");
    }
}