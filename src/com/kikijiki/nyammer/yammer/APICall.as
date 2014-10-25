package com.kikijiki.nyammer.yammer
{
	import flash.net.URLRequestMethod;
	
	public class APICall
	{
		public static const RATE_LIMIT_AUTOCOMPLETE :String = "rate_limit_autocomplete";
		public static const RATE_LIMIT_MESSAGES     :String = "rate_limit_messages";
		public static const RATE_LIMIT_NOTIFICATIONS:String = "rate_limit_notifications";
		public static const RATE_LIMIT_OTHER        :String = "rate_limit_other";
		public static const RATE_UNLIMITED          :String = "rate_unlimited";
		
		public static const DATA_FORMAT_JSON:String = "JSON";
		public static const DATA_FORMAT_TEXT:String = "text";
		
		public var url:String;
		public var method:String;
		public var format:String;
		public var resultFormat:String;
		public var rateLimit:String;
		
		public function APICall(url:String, method:String, format:String, resultFormat:String, rateLimit:String)
		{
			this.url = url;
			this.method = method;
			this.format = format;
			this.resultFormat = resultFormat;
			this.rateLimit = rateLimit;
		}
	}
}