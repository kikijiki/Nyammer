package com.kikijiki.nyammer.models
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import com.kikijiki.nyammer.async.AsyncUserLoadTask;
	import com.kikijiki.nyammer.async.SequentialExecution;
	import com.kikijiki.nyammer.components.NetworkComponent;
	import com.kikijiki.nyammer.events.UserListUpdatedEvent;
	import com.kikijiki.nyammer.uti.LocalBinaryCache;
	import com.kikijiki.nyammer.views.UserIcon;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.collections.ListCollectionView;
	
	import spark.components.gridClasses.GridColumn;
	import spark.events.TextOperationEvent;

	[Bindable]
	[Event(name="userListUpdated", type="com.kikijiki.events.UserListUpdatedEvent")]
	public class UserListModel extends EventDispatcher
	{
		public var loadFinished:Boolean = false;
		public var incomplete:Boolean = true;
		private var users:Dictionary = new Dictionary();
		private var usersList:ArrayCollection = new ArrayCollection();
		public var loggedUser:UserModel;
		
		private var queue:SequentialExecution = new SequentialExecution(); 
		private var fileCache:LocalBinaryCache;
		private var iconCache:IconCache;
		private var network:NetworkModel;

		public function UserListModel(network:NetworkModel):void
		{
			this.network = network;
			fileCache = new LocalBinaryCache("cache/" + network.permalink + "/users/", fileCacheLoader);
			iconCache = new IconCache("cache/" + network.permalink + "/icons/");
		}
		public function addUser(data:Object):UserModel
		{
			if(users[data["id"]] != null){ return null; }
			
			var user:UserModel = UserModel.parseUser(data, network);
			var old:UserModel = users[user.id];

			if(old != null)
			{
				old.updateData(user.data);
			}
			else
			{
				importUser(user);
			}
			
			saveToFileCache(user);

			return user;
		}
		
		private function importUser(user:UserModel):void
		{
			users[user.id] = user;
			usersList.addItem(user);
			dispatchEvent(new UserListUpdatedEvent(false));
		}

		public function getUser(id:String):UserModel
		{
			var user:UserModel = users[id];
			
			if(!user)
			{
				user = new UserModel(network);
				user.id = id;
				importUser(user);
				
				queue.add(new AsyncUserLoadTask(network, user, function(success:Boolean, userData:UserModel):void
				{
					if(success)
					{
						user.updateData(userData.data);
						saveToFileCache(user);
					}
				}));
				queue.execute();
			}
			
			return user;
		}
		
		public function setLoadFinished(success:Boolean = true):void
		{
			this.loadFinished = true;
			this.incomplete = !success;
			dispatchEvent(new UserListUpdatedEvent(true));
		}
		
		public function createDataView():ListCollectionView
		{
			return new ListCollectionView(usersList);
		}
		
		public function clear():void
		{
			for(var key:* in users){ delete users[key]; }
			usersList.removeAll();
			incomplete = true;
			loadFinished = false;
		}
		
		public function clearCache():void
		{
			fileCache.clear();
		}
		
		public function setLoggedUser(id:String):UserModel
		{
			loggedUser = getUser(id);
			return loggedUser;
		}
		
		private function saveToFileCache(user:UserModel):void
		{
			var buf:ByteArray = new ByteArray();
			buf.writeUTFBytes(JSON.stringify(user.data));
			fileCache.save(user.id, buf);
		}
		
		private function fileCacheLoader(id:String, data:ByteArray):void
		{
			var tmp:Object = JSON.parse(data.readUTFBytes(data.length));
			var user:UserModel = UserModel.parseUser(tmp, network);
			importUser(user);
		}
		
		public function loadCache():void
		{
			loadFinished = fileCache.loadAll() > 0;
		}
		
		public function setIcon(user:UserModel, target:UserIcon):void
		{
			iconCache.setIcon(user, target);
		}
	}
}