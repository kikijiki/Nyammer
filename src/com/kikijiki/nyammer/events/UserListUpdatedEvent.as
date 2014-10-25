package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class UserListUpdatedEvent extends Event
	{
		public var completed:Boolean;
		
		public function UserListUpdatedEvent(completed:Boolean)
		{
			super("userListUpdated");
			this.completed = completed;
		}
	}
}