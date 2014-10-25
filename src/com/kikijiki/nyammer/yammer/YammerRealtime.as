package com.kikijiki.nyammer.yammer
{
	import flash.display.LoaderInfo;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.NetworkInfo;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import com.kikijiki.nyammer.events.MessageEvent;
	import com.kikijiki.nyammer.events.RealtimeStatusChangedEvent;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.windows.PopupWindow;
	
	import mx.collections.ArrayList;
	import mx.rpc.events.FaultEvent;

	/**
	 * 流れ：
	 * Initialization -> Handshake -> Subscribe -> Connect
	 **/
	[Bindable]
	[Event(name="realtimeMessage", type="com.kikijiki.nyammer.events.MessageEvent")]
	[Event(name="realtimeStatusChanged", type="com.kikijiki.nyammer.events.RealtimeStatusChangedEvent")]
	public class YammerRealtime extends EventDispatcher
	{
		public static const REALTIME_STATUS_DISCONNECTED :String = "realtime_status_disconnected";
		public static const REALTIME_STATUS_CONNECTED    :String = "realtime_status_connected";
		public static const REALTIME_STATUS_CONNECTING   :String = "realtime_status_connecting";
		
		private var realtimeURI:String;
		private var authenticationToken:String;
		private var clientId:String;
		
		private var active:Boolean = false;
		private var timeout:int = 30000;
		
		private var intervals:ArrayList = new ArrayList();
		private var requestId:int = 0;
		
		private var network:NetworkModel;
		
		private var _status:String = REALTIME_STATUS_DISCONNECTED;
		public function get status():String
		{
			return _status;
		}
		
		public function set status(v:String):void
		{
			if(v != _status)
			{
				_status = v;
				dispatchEvent(new RealtimeStatusChangedEvent(_status));
			}
		}

		public function YammerRealtime(network:NetworkModel):void
		{
			this.network = network;
		}

		public function start():void
		{
			active = true;
			status = YammerRealtime.REALTIME_STATUS_CONNECTING;
			initialize();
		}
		
		public function stop():void
		{
			invalidate();
			for each(var intervalId:uint in intervals)
			{
				clearTimeout(intervalId);
			}
			active = false;
			status = YammerRealtime.REALTIME_STATUS_DISCONNECTED;
		}
		
		private function invalidate():void
		{
			realtimeURI = null;
			authenticationToken = null;
			clientId = null;
		}
		
		private function reschedule():void
		{
			if(active)
			{
				status = YammerRealtime.REALTIME_STATUS_CONNECTING;
				invalidate();
				intervals.addItem(setTimeout(initialize, 500));
			}
		}
		
		private function initialize():void
		{
			network.makeRequest(YammerAPI.REALTIME_INITIALIZATION)
			.setListener(function(success:Boolean, data:Object):void
			{
				if(success)
				{
					realtimeURI = data["realtimeURI"];
					authenticationToken = data["authentication_token"];
					handshake();
				}
				else
				{
					reschedule();
				}
			})
			.execute();
		}
		
		private function nextId():int
		{
			return ++requestId;
		}
		
		private function adjustTimeout(data:Object):void
		{
			if(data["advice"] != null && data["advice"]["timeout"] != null)
			{
				timeout = data["advice"]["timeout"];
			}
		}
		
		private function handshake():void
		{
			new YammerRequest(YammerAPI.REALTIME)
			.setUrl(realtimeURI + "handshake")
			.setMethod("POST")
			.setFormat("JSON")
			.setResultFormat("text")
			.setContentType("application/json")
			.setParameters(JSON.stringify([{
				ext:
				{
					token:authenticationToken
				},
				version:"1.0",
				minimumVersion:"0.9",
				channel:"/meta/handshake",
				supportedConnectionTypes:["long-polling"],
				id:nextId()
			}]))
			.setListener(function(success:Boolean, data:Object):void
			{
				if(data != null && data.hasOwnProperty(0))
				{
					data = data[0];
				}
				else
				{
					reschedule();
				}
				
				if(success && data["successful"])
				{
					clientId = data["clientId"];
					adjustTimeout(data);
					
					subscribe();
				}
				else
				{
					reschedule();
				}
			})
			.execute();
		}
		
		private function subscribe():void
		{
			//First find the channel id for the private message feed.
			network.makeRequest(YammerAPI.PRIVATE_MESSAGES)
			.setListener(function(success:Boolean, data:Object):void
			{
				if(success)
				{
					var privateMessageChannel:String = data["meta"]["realtime"]["channel_id"];
					
					new YammerRequest(YammerAPI.REALTIME)
					.setUrl(realtimeURI)
					.setMethod("POST")
					.setFormat("JSON")
					.setResultFormat("text")
					.setContentType("application/json")
					.setParameters(JSON.stringify([
						{
							"channel":"/meta/subscribe",
							"subscription":"/feeds/" + privateMessageChannel + "/primary",
							"id":nextId(),
							"clientId":clientId
						},
						{
							"channel":"/meta/subscribe",
							"subscription":"/feeds/" + privateMessageChannel + "/secondary",
							"id":nextId(),
							"clientId":clientId
						}
					]))
					.setListener(function(success:Boolean, data:Object):void
					{
						//TODO: check successful == true?
						
						if(success)
						{
							connect();
							status = YammerRealtime.REALTIME_STATUS_CONNECTED;
						}
						else
						{
							reschedule();
						}
					})
					.execute();
				}
				else
				{
					reschedule();
				}
			})
			.execute(true);
		}
		
		private function connect():void
		{
			new YammerRequest(YammerAPI.REALTIME)
			.setUrl(realtimeURI + "connect")
			.setMethod("POST")
			.setFormat("JSON")
			.setResultFormat("text")
			.setContentType("application/json")
			.setParameters(JSON.stringify([{
				"channel":"/meta/connect",
				"connectionType":"long-polling",
				"id":nextId(),
				"clientId":clientId
			}]))
			.setListener(function(success:Boolean, data:Object):void
			{
				if(success)
				{
					if(data[1] == null) //Nothing new.
					{
						adjustTimeout(data[0]);
					}
					else // Notifications arrived.
					{
						dispatchEvent(new MessageEvent(data));
					}
					
					connect();
				}
				else
				{
					var event:FaultEvent = data as FaultEvent;
					
					if(event.statusCode == 404) //timeout
					{
						connect();
					}
					else
					{
						reschedule();
					}
				}
			})
			.execute();
		}
	}
}