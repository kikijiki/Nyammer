package com.kikijiki.nyammer.uti
{
	import flash.display.DisplayObject;
	
	import mx.controls.ProgressBar;
	import mx.managers.PopUpManager;

	public class SimpleProgressBar
	{
		private var progressBar:ProgressBar;
		private var parent:DisplayObject;
		
		public function SimpleProgressBar(parent:DisplayObject)
		{
			this.parent = parent;
		}
		
		public function show(message:String):void
		{
			if(progressBar)
			{
				PopUpManager.removePopUp(progressBar);
			}
			
			progressBar = new ProgressBar();
			progressBar.width = 200;
			progressBar.indeterminate = true;
			progressBar.labelPlacement = "center";
			progressBar.setStyle("removedEffect", "fade");
			progressBar.setStyle("addedEffect", "fade");
			progressBar.setStyle("color", 0x000000);
			progressBar.setStyle("borderColor", 0x000000);
			progressBar.setStyle("barColor", 0xf4b60f);
			progressBar.label = message;
			
			PopUpManager.addPopUp(progressBar,　parent,　true);
			PopUpManager.centerPopUp(progressBar);
		}
		
		public function hide():void
		{
			if(progressBar)
			{
				PopUpManager.removePopUp(progressBar);
				progressBar.visible = false;
				progressBar = null;
			}
		}
	}
}