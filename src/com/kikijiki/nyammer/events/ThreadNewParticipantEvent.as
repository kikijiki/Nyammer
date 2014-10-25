package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	import com.kikijiki.nyammer.models.UserModel;
	
	public class ThreadNewParticipantEvent extends Event
	{
		public var user:UserModel;
		public function ThreadNewParticipantEvent(user:UserModel)
		{
			super("threadNewParticipant", true, true);
		}
	}
}