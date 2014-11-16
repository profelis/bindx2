package buddy;

import buddy.BuddySuite.Suite;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.TestStatus;

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
class TravisReporter extends ConsoleReporter
{
    override public function done(suites:Iterable<Suite>) 
    {
        var res = super.done(suites);
        
        function successSuite(s : Suite):Bool {
            for (sp in s.steps) switch sp {
                case TSpec(sp) if (sp.status == TestStatus.Failed): return false;
                case TSuite(s) if (!successSuite(s)): return false;
                case _:
            }
            return true;
        };
        var success = suites.foreach(successSuite);
        
        Sys.println('success: ${success}');
        
        return res;
    }
}

#if js

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