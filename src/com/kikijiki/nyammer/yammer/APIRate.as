package com.kikijiki.nyammer.yammer
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayList;
	import mx.utils.StringUtil;

	public class APIRate
	{
		private var limit:int;
		private var resetTime:int;
		
		private var count:int = 0;
		private var timer:Timer;
		private var queue:Array = new Array();
		private var name:String;
		
		private var last:Number = 0;
		
		public function APIRate(name:String, limit:int, resetTime:int)
		{
			this.limit = limit;
			this.resetTime = resetTime;
			this.name = name;
			last = (new Date()).time;
			
			if(limit > 0)
			{
				timer = new Timer(resetTime);
				timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
				{
					timer.stop();
					count = 0;
					last = (new Date()).time;
					
					var tmp:Array = queue.concat();
					queue = [];
					
					for each(var callback:Function in tmp)
					{
						execute(callback);
					}
				});
			}
		}

		public function execute(callback:Function):void
		{
			if(limit < 0)
			{
				callback();
				return;
			}
			
			if(count < limit)
			{
				if(!timer.running)
				{
					timer.start();
				}
				
				callback();
				count++;
			}
			else
			{
				queue.push(callback);
			}
		}
		
		public function getPending():String
		{
			var pending:uint = queue.length;
			if(pending == 0){ return ""; }
			
			var now:uint= (new Date()).time;
			var elapsed:uint = (now - last); 
			var estimate:uint = Math.max(0, Math.ceil(pending / limit) * resetTime - elapsed) / 1000;
			if(estimate == 0){ return ""; }
			
			var formattedEstimate:String;
			if(estimate < 60){ formattedEstimate = estimate.toString() + "秒"; }
			else { formattedEstimate = (Math.floor(estimate / 60)) + "分" + (estimate % 60) + "秒";}
			
			return StringUtil.substitute("待ち状態のリクエスト数：{0}　所要時間：{1}", pending, formattedEstimate);
		}
		
		public function forceExecuteAllNow():void	
		{
			for each(var callback:Function in queue)
			{
				callback();
			}
			
			queue = [];
			timer.stop();
		}
		
		public function discardAll():void	
		{
			queue = [];
			if(timer != null){ timer.stop(); }
		}
	}
}