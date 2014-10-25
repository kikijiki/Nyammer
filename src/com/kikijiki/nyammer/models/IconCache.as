package com.kikijiki.nyammer.models
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import com.kikijiki.nyammer.async.AsyncIconLoadTask;
	import com.kikijiki.nyammer.async.SequentialExecution;
	import com.kikijiki.nyammer.uti.LocalBinaryCache;
	import com.kikijiki.nyammer.views.UserIcon;
	
	import mx.collections.ArrayList;
	
	import org.osmf.events.LoaderEvent;
	
	import spark.components.Image;

	public class IconCache
	{
		private var cache:Dictionary = new Dictionary();
		private var placeholder:BitmapData;
		private var fileCache:LocalBinaryCache;
		
		private var queue:SequentialExecution = new SequentialExecution(4);
		private var requests:Dictionary = new Dictionary();

		public function IconCache(path:String)
		{
			fileCache = new LocalBinaryCache(path, fileCacheLoader);
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void
			{
				placeholder = event.target.content.bitmapData;
			});
			
			loader.load(new URLRequest("assets/images/placeholder.png"));

			fileCache.loadAll();
		}
		
		private function addToQueue(user:UserModel):void
		{
			if(user.icon_url == null || user.icon_url.length == 0){ return; }
			queue.add(new AsyncIconLoadTask(user, function(success:Boolean, data:BitmapData):void
			{
				if(success)
				{
					cache[user.id] = data;
					saveToLocalCache(user.id, data);
				}
				else
				{
					cache[user.id] = placeholder;
				}
				
				updateRequests(user);
			}));
			
			queue.execute();
		}
		
		public function setIcon(user:UserModel, image:UserIcon):void
		{
			if(user && user.id && cache[user.id] != null)
			{
				image.source = cache[user.id];
				return;
			}
			
			if(requests[image] != null && requests[image].id == user.id){ return; }
			
			image.source = getPlaceholder();
			requests[image] = user;
			addToQueue(user);
		}
		
		private function updateRequests(newUser:UserModel):void
		{
			var completed:ArrayList = new ArrayList();
			
			for(var key:Object in requests)
			{
				var icon:UserIcon = key as UserIcon;
				var user:UserModel = requests[key];

				if(user.id == newUser.id)
				{
					var data:BitmapData = cache[user.id];
					icon.setSource(user.id, data);
					completed.addItem(key);
				}
			}
			
			for each(var item:Object in completed)
			{
				requests[item] = null;
			}
		}
		
		private function getPlaceholder():BitmapData
		{
			return placeholder;
		}
		
		private function saveToLocalCache(id:String, data:BitmapData):void
		{		
			var buffer:ByteArray = new ByteArray();
			buffer.writeUnsignedInt(data.width);
			buffer.writeUnsignedInt(data.height);
			buffer.writeBytes(data.getPixels(data.rect));
			
			fileCache.save(id, buffer);
		}
		
		private function fileCacheLoader(id:String, data:ByteArray):void
		{
			var width:uint = data.readUnsignedInt();
			var height:uint = data.readUnsignedInt();
			var bitmapData:BitmapData = new BitmapData(width, height, true, 0);
			bitmapData.setPixels(bitmapData.rect, data);
			cache[id] = bitmapData;
		}
	}
}