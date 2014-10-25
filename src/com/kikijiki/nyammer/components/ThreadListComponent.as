package com.kikijiki.nyammer.components
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import com.kikijiki.nyammer.async.AsyncThreadLoadTask;
	import com.kikijiki.nyammer.async.SequentialExecution;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.controls.List;
	import mx.events.CollectionEvent;
	import mx.utils.ObjectUtil;
	
	import spark.components.Button;
	import spark.components.Panel;
	
	[Bindable]
	public class ThreadListComponent extends Panel
	{
		public var sortedThreadsView:ListCollectionView;
		
		[SkinPart(required="true")]
		public var buttonLoadMoreThreads:Button;
		
		[SkinPart(required="true")]
		public var buttonRefreshThreadList:Button;
		
		private static var dateSortField:SortField = new SortField("date", false, false);
		private static var sortByDate:Sort = new Sort();
		{
			dateSortField.compareFunction = function(a:Object, b:Object):int
			{
				var ta:ThreadModel = a as ThreadModel;
				var tb:ThreadModel = b as ThreadModel;
				return ObjectUtil.dateCompare(tb.getLastDate(), ta.getLastDate());
			}
			
			sortByDate.fields = [dateSortField];
		}
		
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
			sortedThreadsView = new ListCollectionView(network.threadList);
			
			sortedThreadsView.sort = ThreadListComponent.sortByDate;
			sortedThreadsView.filterFunction = function(item:Object):Boolean
			{
				return (item as ThreadModel).preload_complete;
			}
			
			sortedThreadsView.refresh();
			
			network.threadList.addEventListener(CollectionEvent.COLLECTION_CHANGE, function():void{sortedThreadsView.refresh();});
		}
		
		public function ThreadListComponent()
		{
			super();
		}
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			
			if (instance == buttonLoadMoreThreads)
			{
				buttonLoadMoreThreads.addEventListener(MouseEvent.CLICK, function(event:Event):void
				{
					network.loadMoreThreads();
				});
			}
			
			if(instance == buttonRefreshThreadList)
			{
				buttonRefreshThreadList.addEventListener(MouseEvent.CLICK, function(event:Event):void
				{
					network.reloadThreads();
				});
			}
		}
	}
}