package com.kikijiki.nyammer.uti
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class LocalBinaryCache
	{
		private var cacheDir:String;
		private var loader:Function;
		
		public function LocalBinaryCache(path:String, loader:Function):void
		{
			cacheDir = path;
			this.loader=  loader;
			check();
		}
		
		public function loadAll():Number
		{
			var count:Number = 0;
			var cacheDirectory:File = openCacheDir();
			
			for each(var file:File in cacheDirectory.getDirectoryListing())
			{
				load(file);
				count++;
			}
			
			return count;
		}
		
		public function clear():void
		{
			var cacheDirectory:File = openCacheDir();
			for each(var file:File in cacheDirectory.getDirectoryListing())
			{
				file.deleteFile();
			}
		}
		
		public function save(id:String, data:ByteArray):void
		{
			data.compress();
			
			var fs:FileStream = new FileStream();
			fs.open(openCacheDir(id), FileMode.WRITE);
			fs.writeBytes(data);
			fs.close();
		}
		
		public function load(file:File):void
		{
			var id:String = file.name;
			var data:ByteArray = new ByteArray();
			var ldr:URLLoader = new URLLoader();
			ldr.dataFormat = URLLoaderDataFormat.BINARY;
			ldr.addEventListener(Event.COMPLETE, function(event:Event):void
			{
				var data:ByteArray = ldr.data;
				data.uncompress();
				loader(id, data);
			});
			ldr.load(new URLRequest(file.url));
		}
		
		public function check():void
		{
			var cacheDirectory:File = openCacheDir();
			if(!cacheDirectory.exists){ cacheDirectory.createDirectory(); }
		}
		
		private function openCacheDir(id:String = ""):File
		{
			return File.applicationStorageDirectory.resolvePath(cacheDir + id);
		}
	}
}