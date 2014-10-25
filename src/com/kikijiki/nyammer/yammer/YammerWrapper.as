package com.kikijiki.nyammer.yammer
{
	import flash.data.EncryptedLocalStore;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import com.kikijiki.nyammer.events.LoginStatusChangedEvent;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	import com.kikijiki.nyammer.models.UserModel;
	import com.kikijiki.nyammer.windows.LoginWindow;
	
	import mx.charts.chartClasses.DataDescription;
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.controls.Alert;
	import mx.events.Request;
	import mx.logging.Log;
	import mx.utils.StringUtil;

	[Bindable]
	[Event(name="loginStatusChanged", type="com.kikijiki.nyammer.events.LoginStatusChangedEvent")]
	public class YammerWrapper extends EventDispatcher
	{
		//TODO: insert values.
		private static const OAUTH_CLIENT_ID      :String = "";
		private static const OAUTH_CLIENT_SECRET  :String = "";
		private static const OAUTH_REDIRECT_URI   :String = "";
		
		public static const LOGIN_STATUS_LOGGED   :String = "login_status_logged";
		public static const LOGIN_STATUS_UNLOGGED :String = "login_status_unlogged";
		public static const LOGIN_STATUS_BUSY     :String = "login_status_busy";
		
		private var _loginStatus:String = LOGIN_STATUS_UNLOGGED;
		
		public var localSettings:SharedObject = SharedObject.getLocal("nyammer_settings");
		
		public var loggedUser:UserModel;
		public var networks:ArrayCollection = new ArrayCollection();
		public var networkDictionary:Dictionary = new Dictionary();
		public var primaryNetwork:NetworkModel;
		
		public var concurrentRealtimeNotifications:uint = 0;
		public const maximumConcurrentRealtimeNotifications:uint = 3;

		[Bindable(event="loginStatusChanged")]
		public function get loginStatus():String
		{
			return _loginStatus;
		}
		
		//Mixed scope not allowed for getter/setter.
		private function setLoginStatus(status:String):void
		{
			if(_loginStatus == status){return;}
			
			_loginStatus = status;
			dispatchEvent(new LoginStatusChangedEvent(_loginStatus));
		}

		public function login(retry_interval:int):void
		{
			setLoginStatus(LOGIN_STATUS_BUSY);
			var yw:YammerWrapper = this;

			var login:LoginWindow = new LoginWindow();
			
			login.clientId = OAUTH_CLIENT_ID;
			login.clientSecret = OAUTH_CLIENT_SECRET;
			login.redirectURI = OAUTH_REDIRECT_URI;
			
			login.setListener(function(success:Boolean, response:Object):void
			{
				if(!success)
				{
					if(retry_interval > 0)
					{
						setTimeout(function():void
						{
							yw.login(retry_interval);
						}, retry_interval);
					}
					return;
				}
				
				setLoginStatus(LOGIN_STATUS_LOGGED);
				initialize(response);
			});
			
			login.open();
		}
		
		private function addNetwork(network:NetworkModel):void
		{
			networks.addItem(network);
			networkDictionary[network.id] = network;
		}
		
		private function initialize(response:Object):void
		{
			var yw:YammerWrapper = this;
			
			primaryNetwork = new NetworkModel(this);
			primaryNetwork.initialize(response["network"], response["access_token"]["token"], true);
			
			addNetwork(primaryNetwork);
			
			loggedUser = UserModel.parseUser(response["user"], primaryNetwork);
			
			primaryNetwork.makeRequest(YammerAPI.TOKENS)
			.setListener(function(success:Boolean, data:Object):void
			{
				if(!success){ return; }
				
				for each(var networkData:Object in data)
				{
					var id:String = networkData["network_id"];
					if(id != null && networkDictionary[id] == null)
					{
						var network:NetworkModel = new NetworkModel(yw);
						network.initializeExternal(networkData);
						addNetwork(network);
					}
				}
			})
			.execute();
		}
		
		public function getPending():String
		{
			return YammerAPI.getPending();
		}
	}
}