package com.kikijiki.nyammer.yammer
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import com.kikijiki.nyammer.models.NetworkModel;
	
	import mx.collections.ArrayList;
	import mx.messaging.messages.HTTPRequestMessage;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	public class YammerRequest
	{
		private var http:HTTPService = new HTTPService();
		private var format:String;
		private var callback:Function;
		private var call:APICall;
		
		public function YammerRequest(requestId:String = null, network:NetworkModel = null)
		{
			if(requestId)
			{
				call = YammerAPI.get(requestId);
				format = call.format;
				http.resultFormat = call.resultFormat;
				http.method = call.method;
				http.url = YammerAPI.makeUrl(call, network);
			}
		}
		
		public function setMethod(method:String):YammerRequest
		{
			http.method = method;
			return this;
		}
		
		public function setUrl(url:String):YammerRequest
		{
			http.url = url;
			return this;
		}
		
		public function appendToUrl(value:String):YammerRequest
		{
			http.url += "/" + value;
			return this;
		}
		
		public function setResultFormat(format:String):YammerRequest
		{
			http.resultFormat = format;
			return this;
		}
		
		public function setFormat(format:String):YammerRequest
		{
			this.format = format;
			return this;
		}
		
		public function setContentType(contentType:String):YammerRequest
		{
			http.contentType = contentType;
			return this;
		}

		public function setToken(token:String):YammerRequest
		{
			http.headers["Authorization"] = "Bearer " + token;
			return this;
		}
		
		public function setParameter(name:String, value:Object):YammerRequest
		{
			if(value != null){ http.request[name] = value;}
			return this;
		}
		
		public function setParameters(data:Object):YammerRequest
		{
			http.request = data;
			return this;
		}
		
		public function setHeader(name:String, value:Object):YammerRequest
		{
			http.headers[name] = value;
			return this;
		}
		
		public function setHeaders(data:Object):YammerRequest
		{
			http.headers = data;
			return this;
		}
		
		public function setTimeout(timeout:int):YammerRequest
		{
			http.requestTimeout = timeout;
			return this;
		}
		
		public function onFault(event:FaultEvent):void
		{
			trace(event);
			if(callback != null){callback(false, event);}
		}
	
		private function onResult(event:ResultEvent):void
		{
			var result:* = event.result;
			
			if(format == APICall.DATA_FORMAT_JSON)
			{
				result = JSON.parse(result);
			}
			
			if(callback != null){callback(true, result);}
		}
		
		public function execute(immediate:Boolean = false):void
		{
			if(format == APICall.DATA_FORMAT_JSON)
			{
				http.url += ".json";
			}
			
			YammerAPI.execute(call, function():void
			{
				http.addEventListener(ResultEvent.RESULT, onResult);
				http.addEventListener(FaultEvent.FAULT, onFault);
				http.send();
			}, immediate);
		}
		
		public function setListener(callback:Function):YammerRequest
		{
			this.callback = callback;
			return this;
		}
	}
}