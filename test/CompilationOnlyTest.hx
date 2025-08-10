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
 * Compilation-only test for working Elixir extern definitions
 * Tests that all extern modules compile without runtime errors
 */
class CompilationOnlyTest extends Test {
    
    /**
     * Test extern class accessibility
     */
    public function testExternClassAccess() {
        // Just test that we can access the class types - no function calls
        var enumClass: Class<Dynamic> = Enumerable;
        var mapClass: Class<Dynamic> = ElixirMap;
        var listClass: Class<Dynamic> = ElixirList;
        var stringClass: Class<Dynamic> = ElixirString;
        var processClass: Class<Dynamic> = ElixirProcess;
        var genServerClass: Class<Dynamic> = GenServer;
        
        // All classes should be accessible
        Assert.notNull(enumClass, "Enumerable class should be accessible");
        Assert.notNull(mapClass, "ElixirMap class should be accessible");
        Assert.notNull(listClass, "ElixirList class should be accessible");
        Assert.notNull(stringClass, "ElixirString class should be accessible");
        Assert.notNull(processClass, "ElixirProcess class should be accessible");
        Assert.notNull(genServerClass, "GenServer class should be accessible");
    }
    
    /**
     * Test ElixirAtom enum values
     */
    public function testElixirAtomValues() {
        // Test that ElixirAtom enum values exist
        var okAtom = ElixirAtom.OK;
        var replyAtom = ElixirAtom.REPLY;
        var noreplyAtom = ElixirAtom.NOREPLY;
        var stopAtom = ElixirAtom.STOP;
        var continueAtom = ElixirAtom.CONTINUE;
        var hibernateAtom = ElixirAtom.HIBERNATE;
        
        // All enum values should be defined
        Assert.notNull(okAtom, "ElixirAtom.OK should be defined");
        Assert.notNull(replyAtom, "ElixirAtom.REPLY should be defined");
        Assert.notNull(noreplyAtom, "ElixirAtom.NOREPLY should be defined");
        Assert.notNull(stopAtom, "ElixirAtom.STOP should be defined");
        Assert.notNull(continueAtom, "ElixirAtom.CONTINUE should be defined");
        Assert.notNull(hibernateAtom, "ElixirAtom.HIBERNATE should be defined");
    }
    
    /**
     * Test GenServer constants
     */
    public function testGenServerConstants() {
        // Test GenServer constants
        var genOk = GenServer.OK;
        var genReply = GenServer.REPLY;
        var genNoreply = GenServer.NOREPLY;
        var genStop = GenServer.STOP;
        var genContinue = GenServer.CONTINUE;
        var genHibernate = GenServer.HIBERNATE;
        
        // All constants should be accessible
        Assert.notNull(genOk, "GenServer.OK should be accessible");
        Assert.notNull(genReply, "GenServer.REPLY should be accessible");
        Assert.notNull(genNoreply, "GenServer.NOREPLY should be accessible");
        Assert.notNull(genStop, "GenServer.STOP should be accessible");
        Assert.notNull(genContinue, "GenServer.CONTINUE should be accessible");
        Assert.notNull(genHibernate, "GenServer.HIBERNATE should be accessible");
    }
    
    /**
     * Test helper function type accessibility
     */
    public function testHelperFunctionTypes() {
        // Test that helper function types exist (but don't call them)
        var replyHelper = GenServer.replyTuple;
        var noreplyHelper = GenServer.noreplyTuple;
        var stopHelper = GenServer.stopTuple;
        var continueHelper = GenServer.continueTuple;
        var hibernateHelper = GenServer.hibernateTuple;
        
        // All helper functions should have types
        Assert.notNull(replyHelper, "GenServer.replyTuple should be accessible");
        Assert.notNull(noreplyHelper, "GenServer.noreplyTuple should be accessible");
        Assert.notNull(stopHelper, "GenServer.stopTuple should be accessible");
        Assert.notNull(continueHelper, "GenServer.continueTuple should be accessible");
        Assert.notNull(hibernateHelper, "GenServer.hibernateTuple should be accessible");
    }
}

#end