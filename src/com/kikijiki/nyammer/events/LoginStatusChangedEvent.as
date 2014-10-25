package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class LoginStatusChangedEvent extends Event
	{
		public var status:String;
		
		public function LoginStatusChangedEvent(status:String)
		{
			super("loginStatusChanged");
			this.status = status;
		}
	}
}