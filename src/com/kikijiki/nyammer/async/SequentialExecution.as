package com.kikijiki.nyammer.async
{
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayList;
	import mx.utils.LinkedList;

	public class SequentialExecution
	{
		private var tasks:ArrayList = new ArrayList();
		private var ids:Dictionary = new Dictionary();
		private var callback:Function;
		private var executing:int = 0;
		private var limit:int = 1;
		
		public function SequentialExecution(limit:uint = 1):void
		{
			this.limit = limit;
		}
		
		public function add(task:AsyncTask):SequentialExecution
		{
			if(ids[task.id] == true){ return this; }
			
			task.callback = this.taskCallback;
			tasks.addItem(task);
			ids[task.id] = true;
			return this;
		}
		
		public function getLength():int
		{
			return tasks.length;
		}
		
		public function setCallback(callback:Function):SequentialExecution
		{
			this.callback = callback;
			return this;
		}
		
		private function taskCallback(... args:*):void
		{
			executeNextTask();
			if(executing > 0){ executing--; }
		}
		
		private function executeNextTask():void
		{
			if(tasks.length > 0)
			{
				var task:AsyncTask = tasks.removeItemAt(0) as AsyncTask;
				task.enableTimeout();
				task.execute();
				executing++;
				ids[task.id] = false;
			}
			else
			{
				if(callback != null){ callback(); }
			}
		}
		
		public function execute(force:Boolean = false):void
		{
			if(executing >= limit && !force){ return; }
			executeNextTask();
		}
	}
}