package com.kikijiki.nyammer.async
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import com.kikijiki.nyammer.models.UserModel;

	public class AsyncIconLoadTask extends AsyncTask
	{
		private var user:UserModel;
		private var loadCallback:Function;
		
		public function AsyncIconLoadTask(user:UserModel, callback:Function)
		{
			super();
			this.user = user;
			loadCallback = callback;
			task = function():void
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void
				{
					var data:BitmapData = event.target.content.bitmapData;
					loadCallback(true, data);
					finished();
				});
				
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
				{
					trace("Could not load the icon of user " + user.fullName + " [" + user.id+ "] @ " + user.icon_url);
				});
				
				loader.load(new URLRequest(user.icon_url));
			}
		}
		
		override public function get id():String
		{
			return user.id;
		}
	}
}