package com.kikijiki.nyammer.async
{
	import com.kikijiki.nyammer.models.ThreadModel;

	public class AsyncThreadLoadTask extends AsyncTask
	{
		private var thread:ThreadModel;
		
		public function AsyncThreadLoadTask(thread:ThreadModel)
		{
			this.thread = thread;
			task = function():void
			{
				thread.preload(this.finished);
			}
		}
		
		override public function get id():String
		{
			return thread.id;
		}
	}
}