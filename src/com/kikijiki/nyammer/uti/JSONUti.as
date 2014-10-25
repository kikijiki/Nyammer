package com.kikijiki.nyammer.uti
{
	public class JSONUti
	{
		public static function getChild(source:Object, name:String, def:* = null):*
		{
			if(source == null){ return def; }
			if(name == null || name.length == 0){ return def; }
			if(!source.hasOwnProperty(name)){ return def; }
			var ret:* = source[name];
			return ret == null ? def : ret;
		}
	}
}