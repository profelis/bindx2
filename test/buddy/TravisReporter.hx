package buddy;

import buddy.BuddySuite.Suite;
import buddy.BuddySuite.Spec;
import buddy.reporting.Reporter;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.TestStatus;
import promhx.Promise;
import promhx.Deferred;

using Lambda;
using StringTools;

#if nodejs
import buddy.internal.sys.NodeJs;
typedef Sys = NodeJs;
#elseif js
typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
typedef Sys = Flash;
#end



/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class TravisReporter implements Reporter
{
    #if php
	var cli : Bool;
	#end
    
    public function new() {}

    public function start()
    {
        #if php
        cli = (untyped __call__("php_sapi_name")) == 'cli';
        if(!cli) Sys.println("<pre>");
        #end
        
        return resolveImmediately(true);
    }
    
    public function progress(spec : Spec)
    {
        Sys.print(switch(spec.status) {
            case TestStatus.Failed: "X";
            case TestStatus.Passed: ".";
            case TestStatus.Pending: "P";
            case TestStatus.Unknown: "?";
        });

        return resolveImmediately(spec);
    }
    
    public function done(suites:Iterable<Suite>) 
    {
        Sys.println("");

        var total = 0;
        var failures = 0;
        var pending = 0;

        var countTests : Suite -> Void = null;
        var printTests : Suite -> Int -> Void = null;

        countTests = function(s : Suite) {
            for (sp in s.steps) switch sp {
                case TSpec(sp):
                    total++;
                    if (sp.status == TestStatus.Failed) failures++;
                    else if (sp.status == TestStatus.Pending) pending++;
                case TSuite(s):
                    countTests(s);
            }
        };

        suites.iter(countTests);

        printTests = function(s : Suite, indentLevel : Int)
        {
            var print = function(str : String) Sys.println(str.lpad(" ", str.length + indentLevel * 2));

            print(s.name);
            for (step in s.steps) switch step
            {
                case TSpec(sp):
                    if (sp.status == TestStatus.Failed)
                    {
                        print("  " + sp.description + " (FAILED: " + sp.error + ")");

                        printTraces(sp);

                        if (sp.stack == null || sp.stack.length == 0) continue;

                        // Display the exception stack
                        for (s in sp.stack) switch s {
                            case FilePos(_, file, line) if (file.indexOf("buddy/internal/") != 0):
                                print('    @ $file:$line');
                            case _:
                        }
                    }
                    else
                    {
                        print("  " + sp.description + " (" + sp.status + ")");
                        printTraces(sp);
                    }
                case TSuite(s):
                    printTests(s, indentLevel+1);
            }
        };

        suites.iter(printTests.bind(_, 0));

        Sys.println('$total specs, $failures failures, $pending pending');
        Sys.println('success: ${failures <= 0}'); // #if travis 
        
        #if php
		if(!cli) Sys.println("</pre>");
		#end

        return resolveImmediately(suites);
    }
    
    function printTraces(spec : Spec)
	{
		for (t in spec.traces)
			Sys.println("    " + t);
	}
    
    private function resolveImmediately<T>(o : T) : Promise<T>
    {
        var def = new Deferred<T>();
        var pr = def.promise();
        def.resolve(o);
        return pr;
    }
}

#if js // && travis)

class Js
{
	private static function replaceSpace(s : String)
	{
		if (js.Browser.navigator.userAgent.indexOf("PhantomJS") >= 0) return s;
		return s.replace(" ", "&nbsp;");
	}

	public static function print(s : String)
	{
        trace(s);
	}

	public static function println(s : String)
	{
        trace(s);
	}
}
#end