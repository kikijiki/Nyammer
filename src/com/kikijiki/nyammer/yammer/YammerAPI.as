package com.kikijiki.nyammer.yammer
{	
	import flash.net.URLRequestMethod;
	import flash.net.dns.AAAARecord;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import com.kikijiki.nyammer.models.NetworkModel;
	
	import mx.utils.StringUtil;
	
	public class YammerAPI
	{
		public static const BASE                   :String = "https://www.yammer.com/";
		public static const API_V1				   :String = "api/v1/";
		
		public static const USERS                  :String = "users";
		public static const PRIVATE_MESSAGES       :String = "private_messages";
		public static const THREADS                :String = "threads";
		public static const MESSAGES               :String = "messages";
		public static const REALTIME_INITIALIZATION:String = "realtime_initialization";
		public static const LOGOUT                 :String = "logout";
		public static const REALTIME               :String = "realtime";
		public static const OAUTH				   :String = "oauth";
		public static const TOKENS				   :String = "tokens";
		public static const NETWORKS			   :String = "networks";
		
		private static const rates:Dictionary = new Dictionary();
		{
			rates[APICall.RATE_LIMIT_AUTOCOMPLETE] = new APIRate("autocomplete", 10, 10*1000);
			rates[APICall.RATE_LIMIT_MESSAGES] = new APIRate("messages", 10, 30*1000);
			rates[APICall.RATE_LIMIT_NOTIFICATIONS] = new APIRate("notifications", 10, 30*1000);
			rates[APICall.RATE_LIMIT_OTHER] = new APIRate("other", 10, 10*1000);
			rates[APICall.RATE_UNLIMITED] = new APIRate("unlimited", -1, -1);
		}

		private static var api:Dictionary = new Dictionary();
		{
			api[USERS] = new APICall(
				"users",
				URLRequestMethod.GET, 
				APICall.DATA_FORMAT_JSON, 
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_OTHER);
			
			api[PRIVATE_MESSAGES] = new APICall(
				"messages/private",
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON, 
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_MESSAGES);
			
			api[THREADS] = new APICall(
				"threads", 
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_MESSAGES);			
			
			api[MESSAGES] = new APICall(
				"messages", 
				URLRequestMethod.POST,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_MESSAGES);
			
			api[REALTIME_INITIALIZATION] = new APICall(
				"realtime", 
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_UNLIMITED);
			
			api[LOGOUT] = new APICall(
				"logout", 
				URLRequestMethod.DELETE,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_UNLIMITED);
			
			api[REALTIME] = new APICall(
				"", 
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_UNLIMITED);
			
			api[OAUTH] = new APICall(
				"oauth",
				URLRequestMethod.POST,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_UNLIMITED);
			
			api[TOKENS] = new APICall(
				"oauth/tokens",
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_OTHER);
			
			api[NETWORKS] = new APICall(
				"networks",
				URLRequestMethod.GET,
				APICall.DATA_FORMAT_JSON,
				APICall.DATA_FORMAT_TEXT, 
				APICall.RATE_LIMIT_OTHER);
		}
		
		public static function get(Id:String):APICall
		{
			return YammerAPI.api[Id];
		}
		
		public static function execute(call:APICall, callback:Function, immediate:Boolean = false):void
		{
			if(immediate)
			{
				callback();
			}
			else
			{
				var rate:APIRate = YammerAPI.rates[APICall.RATE_LIMIT_OTHER];
				if(call){ rate = YammerAPI.rates[call.rateLimit]; }
				rate.execute(callback);
			}
		}
		
		public static function makeUrl(call:APICall, network:NetworkModel = null):String
		{
			var ret:String = YammerAPI.BASE;
			
			if(network != null && network.permalink != null){ ret += network.permalink + "/"; }
			ret += YammerAPI.API_V1;
			ret += call.url;
			return ret;
		}
		
		public static function getPending():String
		{
			return rates[APICall.RATE_LIMIT_MESSAGES].getPending();
		}
		
		public static function forceExecuteAllNow():void
		{
			for each(var rate:APIRate in YammerAPI.rates)
			{
				rate.forceExecuteAllNow();
			}
		}
		
		public static function discardAll():void
		{
			for each(var rate:APIRate in YammerAPI.rates)
			{
				rate.discardAll();
			}
		}
	}
}