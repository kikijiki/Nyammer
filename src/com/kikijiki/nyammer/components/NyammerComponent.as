package com.kikijiki.nyammer.components
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import com.kikijiki.nyammer.*;
	import com.kikijiki.nyammer.events.DeleteRecipientEvent;
	import com.kikijiki.nyammer.events.ListItemClickEvent;
	import com.kikijiki.nyammer.events.LoginStatusChangedEvent;
	import com.kikijiki.nyammer.events.UserListUpdatedEvent;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	import com.kikijiki.nyammer.models.UserListModel;
	import com.kikijiki.nyammer.models.UserModel;
	import com.kikijiki.nyammer.uti.SimpleProgressBar;
	import com.kikijiki.nyammer.views.NetworkListView;
	import com.kikijiki.nyammer.views.NetworkView;
	import com.kikijiki.nyammer.views.ThreadListView;
	import com.kikijiki.nyammer.views.UserListView;
	import com.kikijiki.nyammer.yammer.YammerWrapper;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.collections.SortField;
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ProgressBar;
	import mx.controls.Text;
	import mx.core.FlexGlobals;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	import mx.events.IndexChangedEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	
	import spark.collections.Sort;
	import spark.components.List;
	import spark.components.TextArea;
	import spark.components.Window;
	import spark.components.WindowedApplication;
	import spark.events.GridEvent;
	import spark.events.IndexChangeEvent;
	
	[Bindable]
	public class NyammerComponent extends Window
	{
		public var currentNetwork:NetworkModel;
		public var networks:ListCollectionView;
		public var networkViewStack:NetworkViewStack;
		public var networkListView:NetworkListView;
		
		private var _yammer:YammerWrapper;
		public function set yammer(v:YammerWrapper):void
		{
			if(_yammer == v){ return; }
			if(_yammer != null)
			{
				_yammer.removeEventListener("loginStatusChanged", onLoginStatusChanged);
			}
			
			_yammer = v;
			
			if(v != null)
			{
				_yammer.addEventListener("loginStatusChanged", onLoginStatusChanged);
				networks = new ListCollectionView(_yammer.networks);
			}
		}
		
		private static var primarySortField:SortField = new SortField("primary", false, false);
		private static var nameSortField:SortField = new SortField("name", false, false);
		private static var sortNetworks:Sort = new Sort();
		{
			primarySortField.compareFunction = function(a:Object, b:Object):int
			{
				var n:NetworkModel = a as NetworkModel;
				return n.primary ? -1 : 1;
			}
				
			nameSortField.compareFunction = function(a:Object, b:Object):int
			{
				var na:NetworkModel = a as NetworkModel;
				var nb:NetworkModel = b as NetworkModel;
				return  (na.name > nb.name) ? 1 : -1;
			}
			
			sortNetworks.fields = [primarySortField, nameSortField];
		}
		
		public function NyammerComponent()
		{
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
		}
		
		private function onLoginStatusChanged(event:LoginStatusChangedEvent):void
		{
			var status:String = event.status;
			
			switch(status)
			{
				case YammerWrapper.LOGIN_STATUS_UNLOGGED:
					close();
					break;
				
				case YammerWrapper.LOGIN_STATUS_BUSY:
					close();
					break;
			}
		}
		
		private function onCreationComplete(event:Event):void
		{
			networkViewStack.selectedIndex = 0;
			networkListView.networkList.addEventListener(IndexChangeEvent.CHANGE, function(event:IndexChangeEvent):void
			{
				networkViewStack.selectedIndex = event.newIndex;
			});
			networkListView.networkList.selectedIndex = 0;
		}
	}
}