package com.kikijiki.nyammer.events
{
	import flash.events.Event;
	
	public class ListItemClickEvent extends Event
	{
		public var item:Object;
		public function ListItemClickEvent(item:Object)
		{
			super("listItemClickEvent", true, true);
			this.item = item;
		}
	}
}