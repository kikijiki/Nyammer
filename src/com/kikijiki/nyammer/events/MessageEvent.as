package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class MessageEvent extends Event
	{
		public var data:Object;
		
		public function MessageEvent(data:Object)
		{
			this.data = data;
			super("message", true, true);
		}
	}
}