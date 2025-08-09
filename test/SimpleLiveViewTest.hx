package test;

import tink.unit.Assert.assert;
import reflaxe.elixir.LiveViewCompiler;

using tink.CoreApi;
using StringTools;

/**
 * Modern Simple LiveView Test Suite with Core Functionality Focus
 * 
 * Tests essential LiveView compilation functionality with simplified approach,
 * complementing the comprehensive LiveViewTest.hx with basic functionality
 * validation and compatibility testing.
 * 
 * Using tink_unittest for modern Haxe testing patterns.
 */
@:asserts
class SimpleLiveViewTest {
    
    public function new() {}
    
    @:describe("LiveView class detection")
    public function testLiveViewDetection() {
        asserts.assert(LiveViewCompiler.isLiveViewClass("TestLiveView"), "Should detect TestLiveView");
        asserts.assert(LiveViewCompiler.isLiveViewClass("UserLiveView"), "Should detect UserLiveView");
        asserts.assert(!LiveViewCompiler.isLiveViewClass("RegularClass"), "Should not detect regular class");
        
        return asserts.done();
    }
    
    @:describe("Socket type generation")
    public function testSocketTypes() {
        var socketType = LiveViewCompiler.generateSocketType();
        asserts.assert(socketType.contains("Phoenix.LiveView.Socket"), "Should reference Phoenix Socket");
        asserts.assert(socketType.contains("assigns"), "Should include assigns");
        
        return asserts.done();
    }
    
    @:describe("Mount function compilation")
    public function testMountCompilation() {
        var mountFn = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        asserts.assert(mountFn.contains("def mount"), "Should generate mount function");
        asserts.assert(mountFn.contains("params, session, socket"), "Should have correct parameters");
        asserts.assert(mountFn.contains("{:ok, socket}"), "Should return {:ok, socket} tuple");
        
        return asserts.done();
    }
    
    @:describe("Event handler compilation")
    public function testEventHandling() {
        var eventFn = LiveViewCompiler.compileHandleEvent(
            "increment",
            "params, socket", 
            "counter = socket.assigns.counter + 1; socket = assign(socket, \"counter\", counter); return {noreply: socket};"
        );
        
        asserts.assert(eventFn.contains("def handle_event"), "Should generate handle_event");
        asserts.assert(eventFn.contains("\"increment\""), "Should include event name");
        asserts.assert(eventFn.contains("{:noreply, socket}"), "Should return noreply tuple");
        
        return asserts.done();
    }
    
    @:describe("Assign compilation")
    public function testAssigns() {
        var assign = LiveViewCompiler.compileAssign("socket", "counter", "0");
        asserts.assert(assign.contains("assign(socket"), "Should call assign function");
        asserts.assert(assign.contains(":counter"), "Should use atom key");
        asserts.assert(assign.contains("0"), "Should include value");
        
        return asserts.done();
    }
    
    @:describe("Module boilerplate")
    public function testBoilerplate() {
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        asserts.assert(boilerplate.contains("defmodule TestLiveView"), "Should create module");
        asserts.assert(boilerplate.contains("use Phoenix.LiveView"), "Should use LiveView");
        asserts.assert(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
        
        return asserts.done();
    }
    
    @:describe("Complete module generation")
    public function testCompleteModule() {
        var module = LiveViewCompiler.compileToLiveView("TestLiveView", "  def test, do: :ok");
        asserts.assert(module.contains("defmodule TestLiveView"), "Should have module declaration");
        asserts.assert(module.contains("use Phoenix.LiveView"), "Should use LiveView");
        asserts.assert(module.contains("def test, do: :ok"), "Should include custom content");
        asserts.assert(module.contains("end"), "Should close module");
        
        return asserts.done();
    }
}