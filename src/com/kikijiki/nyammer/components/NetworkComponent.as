package com.kikijiki.nyammer.components
{
	import com.kikijiki.nyammer.events.ListItemClickEvent;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	import com.kikijiki.nyammer.models.UserModel;
	import com.kikijiki.nyammer.uti.SimpleProgressBar;
	import com.kikijiki.nyammer.views.ThreadListView;
	import com.kikijiki.nyammer.views.UserListView;
	import com.kikijiki.nyammer.yammer.YammerWrapper;
	
	import mx.containers.Canvas;
	import mx.events.FlexEvent;
	
	import spark.events.GridEvent;

	[Bindable]
	public class NetworkComponent extends Canvas
	{
		public var userListView:UserListView;
		public var threadListView:ThreadListView;
		private var progressBar:SimpleProgressBar;
		
		private var _network:NetworkModel;
		
		public function set network(v:NetworkModel):void
		{
			if(_network != v)
			{
				_network = v;
				onNetworkPlugged();
			}
		}
		
		public function get network():NetworkModel
		{
			return _network;
		}
		
		private function onNetworkPlugged():void
		{
			
		}
		
		public function NetworkComponent():void
		{
			this.addEventListener(FlexEvent.CREATION_COMPLETE, function():void
			{
				userListView.userGrid.addEventListener(GridEvent.GRID_DOUBLE_CLICK, function(event:GridEvent):void
				{
					var user:UserModel = event.item as UserModel;
					openPopup(user);
				});
				
				threadListView.addEventListener("listItemClickEvent", function(event:ListItemClickEvent):void
				{
					var thread:ThreadModel = event.item as ThreadModel;
					network.makePopup(thread, false);
				});
			});
		}
		
		
		public function openPopup(recipient:UserModel):void
		{
			network.openOrCreateOOOThread(recipient, function(thread:ThreadModel):void
			{
				if(thread != null)
				{
					thread.preload();
					network.makePopup(thread, false);
				}
			});
		}
	}
}