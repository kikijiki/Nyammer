package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class DeleteRecipientEvent extends Event
	{
		public var recipient:Object;
		public function DeleteRecipientEvent(recipient:Object)
		{
			super("deleteRecipient", true);
			this.recipient = recipient;
		}
	}
}