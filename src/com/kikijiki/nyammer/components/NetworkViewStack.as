package com.kikijiki.nyammer.components
{
	import flash.events.Event;
	
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.views.NetworkView;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.containers.ViewStack;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	
	public class NetworkViewStack extends ViewStack
	{
		private var _networks:ListCollectionView;
		
		public function set networks(v:ListCollectionView):void
		{
			_networks = v;
			
			for each(var network:NetworkModel in _networks)
			{
				addNetwork(network);
			}
			
			_networks.addEventListener(CollectionEvent.COLLECTION_CHANGE, function(event:CollectionEvent):void
			{
				if(event.kind == CollectionEventKind.ADD)
				{
					for each(var network:NetworkModel in event.items)
					{
						addNetwork(network);
					}
				}
			});
		}
		
		public function NetworkViewStack()
		{
			super();
		}
		
		private function addNetwork(network:NetworkModel):void
		{
			var nv:NetworkView = new NetworkView();
			nv.network = network;
			addChild(nv);
		}
	}
}