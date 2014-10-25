package com.kikijiki.nyammer.models
{
	import flash.events.EventDispatcher;
	import flash.net.dns.AAAARecord;
	import flash.utils.Dictionary;
	
	import com.kikijiki.nyammer.components.UserListComponent;
	import com.kikijiki.nyammer.events.ThreadNewParticipantEvent;
	import com.kikijiki.nyammer.events.ThreadUpdatedEvent;
	import com.kikijiki.nyammer.uti.JSONUti;
	import com.kikijiki.nyammer.windows.MarkMessageAsReadWindow;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.collections.ListCollectionView;
	import mx.utils.ObjectUtil;
	
	import spark.collections.Sort;
	import spark.collections.SortField;

	[Bindable]
	[Event(name="threadUpdatedEvent", type="com.kikijiki.events.ThreadUpdatedEvent")]
	[Event(name="threadNewParticipant", type="com.kikijiki.events.ThreadNewParticipant")]
	public class ThreadModel extends EventDispatcher
	{
		public var id:String;
		public var sender:UserModel;
		public var initialMessage:MessageModel;
		public var messages:ArrayCollection = new ArrayCollection();
		public var msgIds:Dictionary = new Dictionary();
		public var url:String;
		public var preload_complete:Boolean = false;
		public var complete:Boolean = false;
		public var excerpt:String;
		public var participants:ArrayCollection = new ArrayCollection();
		public var OOO:Boolean = false;
		public var createdAt:Date;
		public var lastMessageDate:Date;		
		
		public static const userAddedRegex:RegExp = /user:([0-9]+)/;
		
		public var network:NetworkModel;
		
		private static var dateSortField:SortField = new SortField("date", false, false);
		private static var sortByDate:Sort = new Sort();
		{
			dateSortField.compareFunction = function(a:Object, b:Object):int
			{
				return ObjectUtil.dateCompare(a.date, b.date);
			}
				
			sortByDate.fields = [dateSortField];
		}
		
		private var sortPartecipants:Sort = new Sort();
		private var partecipantSortField:SortField = new SortField("partecipant_id", false, false);
		
		private var _unreadCount:int = 0;
		public function get unreadCount():Number
		{
			return _unreadCount;
		}
		
		public function set unreadCount(v:Number):void
		{
			if(v != _unreadCount)
			{
				_unreadCount = v;
				if(network){ network.updateUnreadCount(); }
			}
		}
		
		public function ThreadModel(network:NetworkModel, data:Object, initial:Boolean = false)
		{
			id = data["thread_id"];

			this.network = network;
			messages.sort = ThreadModel.sortByDate;
			
			if(initial)
			{
				parseThreadData(data)
			}
			else
			{
				network.getMessage(id, function(success:Boolean, thread_data:Object):void
				{
					if(success){ parseThreadData(thread_data); }
				});
			}
			
			messages.refresh();
			
			partecipantSortField.compareFunction = function(a:Object, b:Object):int
			{
				if(a == null || sender == null)
				{
					return 1; 
				}
				else
				{
					return a.id == sender.id ? -1 : 1;
				}
			};
			
			sortPartecipants.fields = [partecipantSortField];
			participants.sort = sortPartecipants;
		}
		
		private function parseThreadData(data:Object):void
		{
			url = data["web_url"];
			excerpt = data["content_excerpt"];
			sender = network.users.getUser(data["sender_id"]);
			createdAt = new Date(Date.parse(data["created_at"]));
			
			initialMessage = MessageModel.parse(data, network);
		}
		
		public function preload(callback:Function = null, force:Boolean = false):void
		{
			if(preload_complete && !force)
			{
				if(callback != null){ callback(); }
				return; 
			}
			
			network.getThreadMessages(id, function(success:Boolean, data:Object):void
			{
				if(success)
				{
					loadMessages(data);
					loadParticipants(data);
					complete = !(data["meta"].hasOwnProperty("older_available") && data["meta"]["older_available"] == true);
					preload_complete = true;
				}
				
				if(callback != null){ callback(); }
			});
		}
		
		public function append(msg:MessageModel, silent:Boolean = false):void
		{
			if(msgIds[msg.id] != null)
			{
				var old:MessageModel = msgIds[msg.id];
				old.like_count = msg.like_count;
				old.like_list = msg.like_list;
				return;
			}

			messages.addItem(msg);
			msgIds[msg.id] = msg;
			
			if(!silent)
			{
				unreadCount++;
				dispatchEvent(new ThreadUpdatedEvent(this, msg));
			}
			
			addParticipant(msg.sender.id, true);
			if(msg.subtype == "added_participant")
			{
				var id:String = msg.body_parsed.match(userAddedRegex)[1];
				addParticipant(id, silent);
			}
		}
		
		public function getFirstMessage():MessageModel
		{
			return messages[0];
		}
		
		public function getLastMessage():MessageModel
		{
			return messages[messages.length - 1];
		}
		
		public function getLastDate():Date
		{
			if(messages.length > 0)
			{
				return messages[messages.length - 1].date;
			}
			else
			{
				return createdAt;
			}
		}
		
		public function getReplyToId():String
		{
			return id;
		}
		
		private function loadMessages(data:Object):void
		{
			for each(var message_data:Object in data["messages"])
			{
				append(MessageModel.parse(message_data, network), true);
			}
		}
		
		private function loadParticipants(data:Object):void
		{
			var references:Object = data["references"];
			
			for each(var ref:Object in references)
			{
				if(ref["type"] == "conversation")
				{
					for each(var partecipant:Object in ref["participating_names"])
					{
						addParticipant(partecipant["id"], true);
					}
				}
			}
			
			participants.refresh();
		}
		
		public function markAsRead():void // Workaround.
		{
			if(url)
			{
				var win:MarkMessageAsReadWindow = new MarkMessageAsReadWindow();
				win.url = url;
				win.open();
			}
		}
		
		public function createDataView():ListCollectionView
		{
			return new ListCollectionView(messages);
		}
		
		public function retrieveAllMessages(callback:Function):void
		{
			if(complete)
			{ 
				callback(true);
				return;
			}
			
			network.getAllThreadMessages(id, 
			function(message_data:Object):void
			{
				var msg:MessageModel = MessageModel.parse(message_data, network);
				append(msg, true);
			},
			function(success:Boolean):void{ callback(success); });
		}
		
		public function addParticipant(userId:String, silent:Boolean = false):void
		{
			for each(var user:UserModel in participants)
			{
				if(user.id == userId){ return; }
			}

			var participant:UserModel = network.users.getUser(userId);
			participants.addItem(participant);
			if(!silent)
			{
				dispatchEvent(new ThreadNewParticipantEvent(participant));
			}
		}
		
		public function refresh():void
		{
			preload(null, true);
		}
	}
}