package com.kikijiki.nyammer    
{
	import flash.desktop.*;
	import flash.display.*;
	import flash.events.*;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import com.kikijiki.nyammer.async.AsyncTask;
	import com.kikijiki.nyammer.async.AsyncThreadLoadTask;
	import com.kikijiki.nyammer.async.SequentialExecution;
	import com.kikijiki.nyammer.components.PopupComponent;
	import com.kikijiki.nyammer.events.LoginStatusChangedEvent;
	import com.kikijiki.nyammer.models.MessageModel;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	import com.kikijiki.nyammer.models.UserListModel;
	import com.kikijiki.nyammer.views.UserListView;
	import com.kikijiki.nyammer.windows.PopupWindow;
	import com.kikijiki.nyammer.windows.NyammerWindow;
	import com.kikijiki.nyammer.yammer.YammerAPI;
	import com.kikijiki.nyammer.yammer.YammerRealtime;
	import com.kikijiki.nyammer.yammer.YammerRequest;
	import com.kikijiki.nyammer.yammer.YammerWrapper;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.controls.Alert;
	import mx.core.WindowedApplication;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	
	import spark.components.Window;
	
	public class Nyammer extends WindowedApplication
	{		
		private var trayIconLogged:BitmapData;
		private var trayIconUnlogged:BitmapData;
		private var loginMenuItem:NativeMenuItem;
		private var sendMessageMenuItem:NativeMenuItem;
		
		private var nyammerWindow:NyammerWindow;
		
		private static const tray_icon_logged:String = "assets/icons/icon_16.png";
		private static const tray_icon_unlogged:String = "assets/icons/icon_16mono.png";
		private static const dock_icon_logged:String = "assets/icons/icon_128.png";
		private static const dock_icon_unlogged:String = "assets/icons/icon_128mono.png";
		
		private var yammer:YammerWrapper;
		
		private var updater:AppUpdater = new AppUpdater();
		private var autologin:uint;
		
		public function Nyammer()
		{
			super();
			updater.startAutoCheck();

			var t:Timer = new Timer(200);
			t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
			{
				if(nyammerWindow != null && yammer != null){ nyammerWindow.title = "Nyammer " + yammer.getPending(); }
			});
			t.start();
			
			addEventListener(FlexEvent.CREATION_COMPLETE, function():void
			{
				if(NativeApplication.supportsSystemTrayIcon)
				{
					loadTray(tray_icon_logged, tray_icon_unlogged);
				}
				else
				{
					loadTray(dock_icon_logged, dock_icon_unlogged);
				}
				
				initializeYammer();
			});
		}
		
		// HMhMhmhHmHmhm
		public function loadTray(logged:String, unlogged:String):void
		{
			var loader1:Loader = new Loader();
			loader1.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void
			{
				trayIconUnlogged = event.target.content.bitmapData;
				
				var loader2:Loader = new Loader();
				loader2.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void
				{
					trayIconLogged = event.target.content.bitmapData;
					readyToTray();
				});
				loader2.load(new URLRequest(logged));
			});
			loader1.load(new URLRequest(unlogged));
		}
		
		public function readyToTray():void
		{
			var menu:NativeMenu = new NativeMenu();
			
			sendMessageMenuItem = new NativeMenuItem("送信");
			
			sendMessageMenuItem.addEventListener(Event.SELECT, showMainWindow);
			
			var versionMenuItem:NativeMenuItem = new NativeMenuItem("v" + AppUpdater.getCurrentVersion());
			versionMenuItem.enabled = false;
			
			menu.addItem(versionMenuItem);
			menu.addItem(new NativeMenuItem("", true));
			menu.addItem(sendMessageMenuItem);
			
			if(NativeApplication.supportsSystemTrayIcon)
			{
				var closeMenuItem:NativeMenuItem = new NativeMenuItem("終了");
				closeMenuItem.addEventListener(Event.SELECT, function():void
				{
					NativeApplication.nativeApplication.exit()
				});
				menu.addItem(closeMenuItem);
				
				SystemTrayIcon(NativeApplication.nativeApplication.icon).tooltip = "Nyammer";
				SystemTrayIcon(NativeApplication.nativeApplication.icon).addEventListener(MouseEvent.CLICK, showMainWindow);
				SystemTrayIcon(NativeApplication.nativeApplication.icon).menu = menu;
			}
			
			if(NativeApplication.supportsDockIcon)
			{
				DockIcon(NativeApplication.nativeApplication.icon).addEventListener(InvokeEvent.INVOKE, showMainWindow);
				DockIcon(NativeApplication.nativeApplication.icon).menu = menu;
			}
			
			stage.nativeWindow.visible = false;
			updateDockIcon();
			
			login();
		}
		
		private function updateDockIcon():void
		{
			if(yammer.loginStatus == YammerWrapper.LOGIN_STATUS_LOGGED)
			{
				NativeApplication.nativeApplication.icon.bitmaps = [trayIconLogged];
			}
			else
			{
				NativeApplication.nativeApplication.icon.bitmaps = [trayIconUnlogged];
			}
		}
		
		private function onLoginStatusChange(event:LoginStatusChangedEvent):void
		{
			updateDockIcon();
		}
		
		private function login():void
		{
			yammer.login(1000);
		}
		
		private function showMainWindow(event:Event = null):void
		{
			switch(yammer.loginStatus)
			{
				case YammerWrapper.LOGIN_STATUS_LOGGED:
					if(nyammerWindow == null)
					{
						nyammerWindow = new NyammerWindow();
						nyammerWindow.yammer = yammer;
					}
					
					nyammerWindow.open();
					nyammerWindow.visible = true;
					nyammerWindow.activate();
					nyammerWindow.setFocus();
				break;
				
				case YammerWrapper.LOGIN_STATUS_UNLOGGED:
				break;
				
				case YammerWrapper.LOGIN_STATUS_BUSY:
				break;
			}
		}
		
		private function initializeYammer():void
		{
			yammer = new YammerWrapper();
			yammer.addEventListener("loginStatusChanged", onLoginStatusChange);
		}
	}
}