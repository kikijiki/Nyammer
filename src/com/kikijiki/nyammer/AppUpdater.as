package com.kikijiki.nyammer
{
	import air.update.ApplicationUpdaterUI;
	import air.update.events.UpdateEvent;
	
	import flash.desktop.NativeApplication;
	import flash.events.ErrorEvent;
	import flash.utils.setInterval;
	
	import mx.controls.Alert;

	public class AppUpdater
	{
		private var ui:ApplicationUpdaterUI = new ApplicationUpdaterUI();
		
		public function check():void
		{
			ui.updateURL = "http://update.xml";
			ui.addEventListener(UpdateEvent.INITIALIZED, onUpdate);
			ui.addEventListener(ErrorEvent.ERROR, onError);
			ui.isCheckForUpdateVisible = false;
			ui.isFileUpdateVisible = false;
			ui.isInstallUpdateVisible = false;
			ui.initialize();
		}
		
		public function startAutoCheck(interval:int = (1000 * 60 * 60 * 24)):void
		{
			setInterval(this.check, interval);
		}

		private function onUpdate(event:UpdateEvent):void
		{
			ui.checkNow();
		}

		private function onError(event:ErrorEvent):void
		{
			trace("Updater error:" + event.toString());
		}
		
		public static function getCurrentVersion():String
		{
			var xml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = xml.namespace();
			var version:String = xml.ns::versionNumber;
			return version;
		}
	}
}