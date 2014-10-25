package com.kikijiki.nyammer.async
{
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class AsyncTask
	{
		private var _callback:Function;
		private var _task:Function = fail;
		public var timeout:int = 1000;
		private var timer:uint;
		
		[Bindable]
		public var status:String = "inactive";
		
		public function set callback(v:Function):void
		{
			_callback = v;
		}
		
		public function set task(v:Function):void
		{
			_task = v;
		}
		
		public function execute():void
		{
			status = "active";
			_task();
		}
		
		protected function finished(success:Boolean = true):void
		{
			clearTimeout(timer);
			status = success ? "finished" : "failed";
			if(_callback != null){ _callback(); }
		}
		
		public function get id():String
		{
			return null;
		}
		
		public function fail():void
		{
			clearTimeout(timer);
			status = "failed";
			if(_callback != null){ _callback(false); }
			finished();
		}
		
		public function enableTimeout(timeout:int = -1):void
		{
			if(timeout > 0){ this.timeout = timeout; }
			timer = setTimeout(function():void
			{
				fail();
			}, this.timeout);
		}
	}
}