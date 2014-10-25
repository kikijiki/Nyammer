package com.kikijiki.nyammer.models
{
	import flash.data.EncryptedLocalStore;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.dns.AAAARecord;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import com.kikijiki.nyammer.async.AsyncThreadLoadTask;
	import com.kikijiki.nyammer.async.SequentialExecution;
	import com.kikijiki.nyammer.components.PopupComponent;
	import com.kikijiki.nyammer.events.MessageEvent;
	import com.kikijiki.nyammer.uti.JSONUti;
	import com.kikijiki.nyammer.windows.PopupWindow;
	import com.kikijiki.nyammer.yammer.YammerAPI;
	import com.kikijiki.nyammer.yammer.YammerRealtime;
	import com.kikijiki.nyammer.yammer.YammerRequest;
	import com.kikijiki.nyammer.yammer.YammerWrapper;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;

	[Bindable]
	public class NetworkModel extends EventDispatcher
	{
		private static const MESSAGE_REFRESH_INTERVAL:int = 1000 * 60; // 1 minute
		private static const USERLIST_REFRESH_INTERVAL:int = 1000 * 60 * 60 * 2; // 2 hours
		
		private static const ACCESS_TOKEN_KEY:String = "access_token";
		
		private static const HEADER_ID_PREFIX:String = "{";
		private static const HEADER_ID_POSTFIX:String = "}";
		private static const HEADER_ID_DELIMITER:String = "-";
		private static const HEADER_ID_FORMAT:String = "{0}" + HEADER_ID_DELIMITER + "{1}" + HEADER_ID_DELIMITER + "{2}";
		private static const HEADER_MESSAGE:String = 
			"nyammer p2p private message thread\n" + 
			"このプライベートスレッドは下記2名の nyammer コミュニケーション用に作成されたものです。\n" +
			"{0} <-> {1}\n" +
			"このプライベートスレッドには他者を追加で参加させないでください。\n" +
			HEADER_ID_PREFIX + "{2}" + HEADER_ID_POSTFIX;
		
		private static const headerIdRegex:RegExp = /{([^}]*)}/;
		
		public var yammer:YammerWrapper;
		
		public var primary:Boolean;
		public var name:String;
		public var permalink:String;
		public var id:String;
		public var users:UserListModel;
		public var threads:Dictionary = new Dictionary();
		public var threadList:ArrayCollection = new ArrayCollection();
		public var unreadCount:Number = 0;
		
		private var _accessToken:String;
		private var secret:String;
		
		public var realtime:YammerRealtime;
		
		private var _realtimeEnabled:Boolean = false;
		public function get realtimeEnabled():Boolean
		{
			return _realtimeEnabled;
		}
		public function set realtimeEnabled(v:Boolean):void
		{
			if(v == _realtimeEnabled){ return; }
			
			if(v)
			{
				if(!canEnableRealtime()){ return; }
				
				enableRealtime();
				yammer.concurrentRealtimeNotifications++;
				var networks:Dictionary = yammer.localSettings.data["networks"];
			}
			else
			{
				yammer.concurrentRealtimeNotifications--;
				disableRealtime();
			}
			
			_realtimeEnabled = v;			
			saveSettings();
		}
		
		private var userListRefreshTimer:Timer = new Timer(USERLIST_REFRESH_INTERVAL);

		private var messageRefreshTimer:Timer = new Timer(MESSAGE_REFRESH_INTERVAL);
		private var lastMessageId:String;
		private var lastMessageDate:Date;
		
		private var threadPages:int = 1;
		
		public var popups:Dictionary = new Dictionary();
		
		public function NetworkModel(yammer:YammerWrapper):void
		{
			this.yammer = yammer;
			realtime = new YammerRealtime(this);
			realtime.addEventListener("message", onRealtimeNotification);
			messageRefreshTimer.addEventListener(TimerEvent.TIMER, onMessageRefresh);
			userListRefreshTimer.addEventListener(TimerEvent.TIMER, onUserListRefresh);
		}
		
		private function saveSettings():void
		{
			var settings:Object = yammer.localSettings.data;
			if(!settings.hasOwnProperty("network"))
			{
				settings["network"] = new Dictionary();
			}

			settings["network"][name] = {"realtimeEnabled":realtimeEnabled};
		}
		
		private function loadSettings():void
		{
			var settings:Object = yammer.localSettings.data;
			if(!settings.hasOwnProperty("network")){ return; }
			if(!settings["network"].hasOwnProperty(name)){ return; }
			realtimeEnabled = JSONUti.getChild(settings["network"][name], "realtimeEnabled", false);
		}
		
		public function initialize(data:Object, accessToken:String = null, isPrimary:Boolean = false):void
		{
			parse(data, accessToken, isPrimary);
			retrieveData();
			realtimeEnabled = true;
			initializeUserListAutoUpdate();
		}
		
		public function initializeExternal(data:Object):void
		{
			parseExternal(data);
			retrieveData();
			initializeUserListAutoUpdate();
			
			getLatestMessages(true, function(success:Boolean):void
			{
				// Realtime for external networks is disabled.
				//loadSettings();
				enableMessageRefresh();
			}, true);
		}
		
		private function initializeUserListAutoUpdate():void
		{
			var delay:Number = Math.random() * (1000 * 60 * 10);
			setTimeout(function():void{ userListRefreshTimer.start(); }, delay);
		}
		
		private function enableRealtime():void
		{
			realtime.start();
			disableMessageRefresh();
		}
		
		private function disableRealtime():void
		{
			realtime.stop();
			enableMessageRefresh();
		}
		
		public function canEnableRealtime():Boolean
		{
			return yammer.concurrentRealtimeNotifications < yammer.maximumConcurrentRealtimeNotifications;
		}
		
		private function enableMessageRefresh():void
		{
			messageRefreshTimer.start();
		}
		
		private function disableMessageRefresh():void
		{
			messageRefreshTimer.stop();
		}
		
		public function parse(data:Object, accessToken:String = null, isPrimary:Boolean = false):void
		{
			primary = JSONUti.getChild(data, "is_primary", isPrimary);
			name = JSONUti.getChild(data, "name");
			id = JSONUti.getChild(data, "id");
			permalink = JSONUti.getChild(data, "permalink");
			this.accessToken = JSONUti.getChild(data, "token", accessToken);
		}
		
		public function parseExternal(data:Object):void
		{
			primary = false;
			name = JSONUti.getChild(data, "network_name");
			id = JSONUti.getChild(data, "network_id");
			permalink = JSONUti.getChild(data, "network_permalink");
			accessToken = JSONUti.getChild(data, "token");
			secret = JSONUti.getChild(data, "secret");
			
			//var userId:String = JSONUti.getChild(data, "user_id");
			//users.setLoggedUser(userId);
		}
		
		private function retrieveData():void
		{
			if(accessToken == null){ return; }
			
			users = new UserListModel(this);
			loadUserList();
			loadThreadList();
		}
		
		public function set accessToken(v:String):void
		{
			_accessToken = v;
			
			if(id != null)
			{
				var tokenBytes:ByteArray = new ByteArray();
				tokenBytes.writeUTFBytes(accessToken);
				EncryptedLocalStore.setItem(ACCESS_TOKEN_KEY + id, tokenBytes);
			}
		}
		
		public function get accessToken():String
		{
			return _accessToken;
		}
		
		public function addThread(thread:ThreadModel):void
		{
			threads[thread.id] = thread;
			threadList.addItem(thread);
		}
		
		public function makeRequest(id:String = null):YammerRequest
		{
			return new YammerRequest(id, this).setToken(accessToken);
		}
		
		public function getUserList(addUser:Function, onComplete:Function):void
		{
			getUserListRecursive(addUser, onComplete, 3);
		}
		
		private function getUserListRecursive(addUser:Function, onComplete:Function, retries:int, page:int = 1):void
		{
			makeRequest(YammerAPI.USERS)
			.setParameter("page", page.toString())
				.setListener(function(success:Boolean, data:Object):void
				{
					if(!success)
					{
						retries--;
						if(retries == 0)
						{
							onComplete(false);
							return;
						}
						else
						{
							return getUserListRecursive(addUser, onComplete, retries, page);
						}
					}
					
					var empty:Boolean = true;
					
					for each(var user:Object in data)
					{
						empty = false;					
						addUser(user);
					}
					
					if(empty)
					{
						onComplete(true);
						return;
					}
					else
					{
						getUserListRecursive(addUser, onComplete, retries, page + 1);
					}
				})
				.execute();
		}
		
		public function sendMessage(targetUserId:String, body:String, onComplete:Function = null):void
		{
			if(targetUserId && targetUserId.length > 0)
			{
				makeRequest(YammerAPI.MESSAGES)
				.setParameter("direct_to_id", targetUserId)
					.setParameter("body", body)
					.setListener(onComplete)
					.execute(true); // Don't hang when sending.
			}
		}
		
		public function replyToMessage(messageId:String, body:String, onComplete:Function = null):void
		{
			if(messageId && messageId.length > 0)
			{
				makeRequest(YammerAPI.MESSAGES)
				.setParameter("replied_to_id", messageId)
					.setParameter("body", body)
					.setListener(onComplete)
					.execute(true); // Don't hang when sending.
			}
		}
		
		public function getUser(id:String, callback:Function):void
		{
			makeRequest(YammerAPI.USERS)
			.appendToUrl(id)
				.setListener(callback)
				.execute();
		}
		
		public function getMessage(id:String, callback:Function):void
		{
			makeRequest(YammerAPI.MESSAGES)
			.appendToUrl(id)
				.setMethod("GET")
				.setListener(callback)
				.execute();
		}
		
		public function getThread(id:String, callback:Function):void
		{
			makeRequest(YammerAPI.THREADS)
			.appendToUrl(id)
				.setListener(callback)
				.execute();
		}
		
		public function getThreadMessages(id:String, callback:Function):void
		{
			makeRequest(YammerAPI.MESSAGES)
			.appendToUrl("in_thread")
				.appendToUrl(id)
				.setListener(callback)
				.execute();
		}
		
		public function getAllThreadMessages(id:String, addMessage:Function, callback:Function):void
		{
			getAllThreadMessagesRecursive(id, addMessage, callback);
		}
		
		private function getAllThreadMessagesRecursive(id:String, addMessage:Function, callback:Function, last:String = null):void
		{
			makeRequest(YammerAPI.MESSAGES)
			.appendToUrl("in_thread")
				.appendToUrl(id)
				.setParameter("older_than", last)
				.setListener(function(success:Boolean, data:Object):void
				{
					if(!success){ callback(false); return; }
					
					for each(var message:Object in data["messages"])
					{
						addMessage(message);
						last = message["id"];
					}
					
					if(data["meta"].hasOwnProperty("older_available") && data["meta"]["older_available"] == true)
					{
						getAllThreadMessagesRecursive(id, addMessage, callback, last);
					}
					else
					{
						callback(true);
					}
				})
				.execute();
		}
		
		public function loadMoreThreads(callback:Function = null):void
		{
			var network:NetworkModel = this;
			getPrivateThreads(function(success:Boolean, data:Object):void
			{
				if(success)
				{
					var se:SequentialExecution = new SequentialExecution();
					for each(var thread_data:Object in data["messages"])
					{
						var thread:ThreadModel = new ThreadModel(network, thread_data, true);
						if(threads[thread.id] == null)
						{
							addThread(thread);
							se.add(new AsyncThreadLoadTask(thread));
						}
					}
					se.execute();
					threadPages++;
				}
				if(callback != null){ callback(success) }
			}, 
			threadPages + 1);
		}
		
		public function reloadThreads():void
		{
			threads = new Dictionary();
			threadList.removeAll();
			loadThreadList();
			threadPages = 1;
		}
		
		public function getPrivateMessages(callback:Function):void
		{
			makeRequest(YammerAPI.PRIVATE_MESSAGES)
			.setListener(callback)
				.execute();
		}
		
		public function getPrivateThreads(callback:Function, page:int = 1):void
		{
			makeRequest(YammerAPI.PRIVATE_MESSAGES)
			.setParameter("threaded", "true")
				.setParameter("page", page)
				.setListener(callback)
				.execute();
		}
		
		private function makeOOOId(user:UserModel):String
		{
			return StringUtil.substitute(HEADER_ID_FORMAT, user.id, yammer.loggedUser.id, new Date().time);
		}
		
		private function makeOOOHeader(user:UserModel):String
		{
			var id:String =  makeOOOId(user);
			return StringUtil.substitute(HEADER_MESSAGE, user.fullName, yammer.loggedUser.fullName, id);
		}
		
		private function getOOOSignature(header:String):String
		{
			var matches:Array = header.match(headerIdRegex);
			if(matches && matches.length > 0)
			{
				return matches[matches.length - 1];
			}
			else
			{
				return null;
			}
		}
		
		private function getOOOSignatureData(header:String):Object
		{
			var data:Array = header.split(HEADER_ID_DELIMITER);
			return {user1:data[0], user2:data[1], timestamp:data[2]};
		}
		
		private function checkOOOThread(thread:ThreadModel, user:UserModel):Number
		{
			if(thread == null || thread.initialMessage == null || thread.initialMessage.body == null){ return 0; }
			var signature:String = getOOOSignature(thread.initialMessage.body);
			if(!signature){ return 0; }
			var data:Object = getOOOSignatureData(signature);
			if(data.user1 != user.id && data.user1 != yammer.loggedUser.id){ return 0; }
			if(data.user2 != user.id && data.user2 != yammer.loggedUser.id){ return 0; }
			
			return data.timestamp;
		}
		
		private function createEmptyOOOThread(user:UserModel, callback:Function):void
		{
			var network:NetworkModel = this;
			var header:String = makeOOOHeader(user);
			sendMessage(user.id, header, function(success:Boolean, data:Object):void
			{
				if(success)
				{
					var thread:ThreadModel = new ThreadModel(network, data["messages"][0]);
					addThread(thread);
					callback(thread);
				}
				else
				{
					callback(null);
				}
			});
		}
		
		private function createOOOThread(user:UserModel, body:String, onComplete:Function, callback:Function):void
		{
			createEmptyOOOThread(user, function(thread:ThreadModel):void
			{
				if(thread == null)
				{
					onComplete(false, null);
					return;
				}
				
				replyToMessage(thread.id, body, onComplete);
				callback(thread);
			});
		}
		
		public function searchOOOThread(user:UserModel):ThreadModel
		{
			var latest:Number = 0;
			var target_thread:ThreadModel = null;
			
			for each(var thread:ThreadModel in threadList)
			{
				var timestamp:Number = checkOOOThread(thread, user);
				if(timestamp > latest)
				{
					latest = timestamp;
					target_thread = thread;
				}
			}
			
			return target_thread;
		}
		
		public function openOrCreateOOOThread(user:UserModel, callback:Function):void
		{
			if(!UserModel.isValid(user) || user.id == yammer.loggedUser.id)
			{ 
				callback(null);
				return; 
			}
			
			//Check if a thread is already present.
			var target_thread:ThreadModel = searchOOOThread(user);
			
			if(target_thread)
			{
				//Check if thread is valid (participants).
				target_thread.preload(function():void
				{
					if(target_thread.participants.length == 2)
					{
						callback(target_thread);
					}
					else
					{
						//If not, create new thread, save it and reply there.
						createEmptyOOOThread(user, callback);
					}
				});
			}
			else
			{
				//Create a new thread.
				createEmptyOOOThread(user, callback);
			}
		}
		
		public function sendOOOMessage(user:UserModel, body:String, onComplete:Function, callback:Function):void
		{
			openOrCreateOOOThread(user, function(target_thread:ThreadModel):void
			{
				if(target_thread == null)
				{
					onComplete(false, null);
					return; 
				}
				else
				{
					replyToMessage(target_thread.id, body, onComplete);
				}
			});
		}
		
		public function updateUserModel(user:UserModel, callback:Function = null):void
		{
			if(!UserModel.isValid(user))
			{
				if(callback != null){ callback(false, null); }
				return 
			};

			getUser(user.id, function(success:Boolean, data:Object):void
			{
				if(success)
				{
					user.updateData(data);
				}
				if(callback != null){ callback(success, user); }
			});
		}
		
		public function loadUserList(force:Boolean = false):void
		{
			if(users.loadFinished && !force){ return; }
			
			users.clear();
			
			if(force)
			{
				users.clearCache();
			}
			else
			{
				users.loadCache();
				if(users.loadFinished)
				{
					users.setLoadFinished(true);
					return;
				}
			}
			
			getUserList(
				function(data:Object):void
				{
					users.addUser(data);
				},
				function(success:Boolean):void
				{
					users.setLoadFinished(success);
				});
		}
		
		public function loadThreadList():void
		{
			var network:NetworkModel = this;
			
			getPrivateThreads(function(success:Boolean, data:Object):void
			{
				if(success)
				{
					var se:SequentialExecution = new SequentialExecution();
					for each(var thread_data:Object in data["messages"])
					{
						if(threads[thread_data["thread_id"]] != null){ continue; }
						var thread:ThreadModel = new ThreadModel(network, thread_data, true);
						addThread(thread);
						se.add(new AsyncThreadLoadTask(thread));
					}
					se.execute();
				}
			});
		}
		
		public function makePopup(thread:ThreadModel, hidden:Boolean = true):PopupWindow
		{
			var popup:PopupWindow = popups[thread.id];
			
			if(popup != null)
			{
				popup.activate();
				return popup;
			}
			else
			{
				popup = new PopupWindow();
				popup.addEventListener(Event.CLOSE, function():void
				{
					popups[thread.id] = null;
				});
				popup.load(thread);
				popups[thread.id] = popup;
			}
				
			popup.open();
			popup.activate();
			if(!hidden){ popup.showThread(); }
			
			return popup;
		}
		
		private function updateThread(message:Object, sender:Object, self:Boolean = false):void
		{
			var thread_id:String = message.thread_id;
			var thread:ThreadModel = threads[thread_id]
			
			if(!thread)
			{
				thread = new ThreadModel(this, message, false);
				addThread(thread);
			}
			else
			{
				var msg:MessageModel = MessageModel.parse(message, this);
				//var silent:Boolean = self || (popup != null && popup.isShown());
				thread.append(msg, self);
			}
			
			if(!self)
			{
				makePopup(thread);
			}
		}
		
		public function updateUnreadCount():void
		{
			unreadCount = 0;
			
			for each(var thread:ThreadModel in threads)
			{
				if(thread.unreadCount > 0){ unreadCount++; }
			}
		}
		
		private function onNewMessage(message:Object, references:Object, currentId:String, silent:Boolean = false):void
		{
			if(message["sender_type"] != "user"){ return; }
			
			var senderId:String = message["sender_id"];
			var self:Boolean = (senderId == currentId);
			var sender:Object;
			
			for each(var reference:Object in references)
			{
				if(reference.hasOwnProperty("type")
					&& reference["type"] == "user"
					&& reference["id"] == message["sender_id"])
				{
					sender = reference;
				}
			}
			
			var msgDate:Date = new Date(Date.parse(JSONUti.getChild(message, "created_at")));
			
			if(lastMessageId == null || ObjectUtil.dateCompare(msgDate, lastMessageDate) > 0)
			{
				lastMessageId = message["id"];
				lastMessageDate = msgDate;
			}
			
			if(!silent){ updateThread(message, sender, self); }
		}
		
		private function getLatestMessages(silent:Boolean = false, callback:Function = null, immediate:Boolean = false):void
		{
			makeRequest(YammerAPI.PRIVATE_MESSAGES)
			.setParameter("newer_than", lastMessageId)
			.setListener(function(success:Boolean, data:Object):void
			{
				if(!success){ return; }
			
				var messages:Object = data["messages"];
				var references:Object = data["references"];
				var currentId:String = data["meta"]["current_user_id"];
				
				for each(var message:Object in messages)
				{
					onNewMessage(message, references, currentId, silent);
				}
				
				if(callback != null){ callback(success); }
			})
			.setTimeout(1000)
			.execute(immediate);
		}
		
		private function onRealtimeNotification(event:MessageEvent):void
		{
			var data0:Object = event.data[0]["data"]["data"];
			
			var currentId:String = data0["meta"]["current_user_id"];
			var messages:Object = data0["messages"];
			var references:Object = data0["references"];
		
			for each(var message:Object in messages)
			{
				onNewMessage(message, references, currentId);
			}
		}
		
		private function onMessageRefresh(event:TimerEvent):void
		{
			disableMessageRefresh();
			getLatestMessages(false, function(success:Boolean):void
			{
				enableMessageRefresh();
			});
		}
		
		private function onUserListRefresh(event:TimerEvent):void
		{
			getUserList(
				function(data:Object):void
				{
					users.addUser(data);
				},
				function(success:Boolean):void
				{
					users.setLoadFinished(success);
				}
			);
		}
	}
}