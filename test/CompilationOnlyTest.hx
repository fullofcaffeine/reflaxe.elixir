package test;

#if (macro || reflaxe_runtime)

import utest.Test;
import utest.Assert;
import elixir.WorkingExterns.Enumerable;
import elixir.WorkingExterns.ElixirMap;
import elixir.WorkingExterns.ElixirList;
import elixir.WorkingExterns.ElixirString;
import elixir.WorkingExterns.ElixirProcess;
import elixir.WorkingExterns.GenServer;
import elixir.WorkingExterns.ElixirAtom;

/**
 * Modern utest compilation-only test for working Elixir extern definitions
 * Tests that all extern modules compile without runtime errors - focuses on type accessibility
 */
class CompilationOnlyTest extends Test {
    public function new() {
        super();
    }
    
    public function testExternClassCompilation() {
        // Just test that we can access the class types - no function calls
        var enumClass: Class<Dynamic> = Enumerable;
        var mapClass: Class<Dynamic> = ElixirMap;
        var listClass: Class<Dynamic> = ElixirList;
        var stringClass: Class<Dynamic> = ElixirString;
        var processClass: Class<Dynamic> = ElixirProcess;
        var genServerClass: Class<Dynamic> = GenServer;
        
        Assert.isTrue(enumClass != null, "Enumerable class should compile");
        Assert.isTrue(mapClass != null, "ElixirMap class should compile");
        Assert.isTrue(listClass != null, "ElixirList class should compile");
        Assert.isTrue(stringClass != null, "ElixirString class should compile");
        Assert.isTrue(processClass != null, "ElixirProcess class should compile");
        Assert.isTrue(genServerClass != null, "GenServer class should compile");
    }
    
    public function testElixirAtomEnumValues() {
        // Test that ElixirAtom enum values exist
        var okAtom = ElixirAtom.OK;
        var replyAtom = ElixirAtom.REPLY;
        var noreplyAtom = ElixirAtom.NOREPLY;
        var stopAtom = ElixirAtom.STOP;
        var continueAtom = ElixirAtom.CONTINUE;
        var hibernateAtom = ElixirAtom.HIBERNATE;
        
        Assert.isTrue(okAtom != null, "ElixirAtom.OK should be accessible");
        Assert.isTrue(replyAtom != null, "ElixirAtom.REPLY should be accessible");
        Assert.isTrue(noreplyAtom != null, "ElixirAtom.NOREPLY should be accessible");
        Assert.isTrue(stopAtom != null, "ElixirAtom.STOP should be accessible");
        Assert.isTrue(continueAtom != null, "ElixirAtom.CONTINUE should be accessible");
        Assert.isTrue(hibernateAtom != null, "ElixirAtom.HIBERNATE should be accessible");
    }
    
    public function testGenServerConstants() {
        // Test GenServer constants
        var genOk = GenServer.OK;
        var genReply = GenServer.REPLY;
        var genNoreply = GenServer.NOREPLY;
        var genStop = GenServer.STOP;
        var genContinue = GenServer.CONTINUE;
        var genHibernate = GenServer.HIBERNATE;
        
        Assert.isTrue(genOk != null, "GenServer.OK should be accessible");
        Assert.isTrue(genReply != null, "GenServer.REPLY should be accessible");
        Assert.isTrue(genNoreply != null, "GenServer.NOREPLY should be accessible");
        Assert.isTrue(genStop != null, "GenServer.STOP should be accessible");
        Assert.isTrue(genContinue != null, "GenServer.CONTINUE should be accessible");
        Assert.isTrue(genHibernate != null, "GenServer.HIBERNATE should be accessible");
    }
    
    public function testGenServerHelperFunctionTypes() {
        // Test that helper function types exist (but don't call them)
        var replyHelper = GenServer.replyTuple;
        var noreplyHelper = GenServer.noreplyTuple;
        var stopHelper = GenServer.stopTuple;
        var continueHelper = GenServer.continueTuple;
        var hibernateHelper = GenServer.hibernateTuple;
        
        Assert.isTrue(replyHelper != null, "GenServer.replyTuple function should be accessible");
        Assert.isTrue(noreplyHelper != null, "GenServer.noreplyTuple function should be accessible");
        Assert.isTrue(stopHelper != null, "GenServer.stopTuple function should be accessible");
        Assert.isTrue(continueHelper != null, "GenServer.continueTuple function should be accessible");
        Assert.isTrue(hibernateHelper != null, "GenServer.hibernateTuple function should be accessible");
    }
}

#end