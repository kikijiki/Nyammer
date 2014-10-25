package com.kikijiki.nyammer.components
{
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import com.kikijiki.nyammer.events.UserListUpdatedEvent;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.UserListModel;
	import com.kikijiki.nyammer.models.UserModel;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.controls.CheckBox;
	import mx.controls.List;
	import mx.core.ClassFactory;
	import mx.events.FlexEvent;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.components.CheckBox;
	import spark.components.DataGrid;
	import spark.components.Panel;
	import spark.components.gridClasses.GridColumn;
	
	[Bindable]
	public class UserListComponent extends Panel
	{
		public var userGrid:DataGrid;
		public var userListDataView:ListCollectionView;
		public var filter:String = "";
		
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
		
		public function UserListComponent()
		{
			super();

			addEventListener(FlexEvent.CREATION_COMPLETE, function():void
			{
				network.users.addEventListener("userListUpdated", function(event:UserListUpdatedEvent):void
				{
					updateCaption();
					
					if(event.completed)
					{
						sort();
					}
				});
				
				userListDataView = network.users.createDataView();
				userListDataView.filterFunction = filterUsers;
				
				updateCaption();
			});
		}
		
		private function updateCaption():void
		{
			if(network.users.loadFinished)
			{
				title = "ユーザー (" + userListDataView.length + ")";
				if(network.users.incomplete)
				{
					title += "(不完全)";
				}
			}
			else
			{
				title = "ユーザーをロード中 (" + userListDataView.length + ")";
			}
		}
		
		public function sort():void
		{
			var columnIndexes:Vector.<int> = Vector.<int>([1, 2]);
			userGrid.sortByColumns(columnIndexes, true);
		}
		
		public function reload():void
		{
			network.users.clear();
			network.users.clearCache();
			network.loadUserList();
			title = "ユーザーをロード中";
		}

		public function onFilterChange(event:Event):void
		{
			userListDataView.refresh();
			updateCaption();
		}
		
		private function filterUsers(item:UserModel):Boolean
		{
			if(filter.length == 0){ return true; }

			var lower_filter:String = filter.toLowerCase();
			
			if(item.fullName.toLowerCase().indexOf(lower_filter) >= 0)
			{
				return true;
			}
			
			if(item.job.toLowerCase().indexOf(lower_filter) >= 0)
			{
				return true;
			}
			
			if(item.name.toLowerCase().indexOf(lower_filter) >= 0)
			{
				return true;
			}
			
			return false;
		}
		
		public function resetFilter():void
		{
			filter = "";
			userListDataView.refresh();
			updateCaption();
		}
		
		public function openWebsite():void
		{
			navigateToURL(new URLRequest("https://www.yammer.com/" + network.permalink + "/#/inbox/index"), "_blank");
		}
	}
}