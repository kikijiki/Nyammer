package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	import com.kikijiki.nyammer.models.MessageModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	
	public class ThreadUpdatedEvent extends Event
	{
		public var thread:ThreadModel;
		public var message:MessageModel;
		
		public function ThreadUpdatedEvent(thread:ThreadModel, message:MessageModel)
		{
			super("threadUpdatedEvent", true, true);
			this.thread = thread;
			this.message = message;
		}
	}
}