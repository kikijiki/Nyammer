package com.kikijiki.nyammer.components
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	import mx.collections.IList;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	
	import spark.components.List;
	
	[Bindable]
	public class ScrollableList extends List
	{
		public var autoScroll:Boolean = true;
		
		public function ScrollableList():void
		{
			this.addEventListener(FlexEvent.UPDATE_COMPLETE, function():void
			{
				if(autoScroll){ scrollToBottom(); }
			});
		}
		
		public function scrollToBottom():void
		{
			callLater(function():void
			{
				try
				{
					ensureIndexIsVisible(dataProvider.length - 1);
				}
				catch(error:Error){}
			});
		}
	}
}