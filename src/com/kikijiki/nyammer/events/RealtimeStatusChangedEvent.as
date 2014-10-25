package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class RealtimeStatusChangedEvent extends Event
	{
		public var status:String;
		
		public function RealtimeStatusChangedEvent(status:String)
		{
			super("realtimeStatusChanged");
			this.status = status;
		}
	}
}