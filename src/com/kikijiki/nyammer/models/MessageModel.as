package com.kikijiki.nyammer.models
{
	import com.kikijiki.nyammer.uti.JSONUti;
	
	import mx.collections.ArrayCollection;
	import mx.formatters.DateFormatter;

	[Bindable]
	public class MessageModel
	{
		public var id:String;
		public var body:String;
		public var body_parsed:String;
		public var sender:UserModel;
		public var date:Date;
		public var url:String;
		public var repliedToId:String = null;
		public var hasAttachments:Boolean = false;
		public var attachments:ArrayCollection = new ArrayCollection();
		public var read:Boolean = false;
		public var like_count:Number = 0;
		public var like_list:ArrayCollection = new ArrayCollection();
		public var message_type:String;
		public var subtype:String;
		
		private static var dateFormatter:DateFormatter = new DateFormatter();
		{
			dateFormatter.formatString = "YYYY/MM/DD HH:MM:SS";
		}

		public static function parse(data:Object, network:NetworkModel):MessageModel
		{
			var msg:MessageModel = new MessageModel();
			var body:Object = JSONUti.getChild(data, "body");
			
			msg.sender = network.users.getUser(JSONUti.getChild(data, "sender_id"));
			msg.repliedToId = JSONUti.getChild(data, "replied_to_id")
			msg.body = JSONUti.getChild(body, "plain");
			msg.body_parsed = JSONUti.getChild(body, "parsed");
			
			msg.date = new Date(Date.parse(JSONUti.getChild(data, "created_at")));
			msg.url = JSONUti.getChild(data, "web_url");
			msg.id = JSONUti.getChild(data, "id");
			msg.loadAttachments(JSONUti.getChild(data, "attachments"));
			
			var likedBy:Object = JSONUti.getChild(data, "liked_by");
			msg.like_count = JSONUti.getChild(likedBy, "count");
			
			var likedByNames:Object = JSONUti.getChild(likedBy, "names");
			if(likedByNames)
			{
				for each (var user:Object in likedByNames)
				{
					var um:UserModel = network.users.getUser(JSONUti.getChild(user, "user_id"));
					msg.like_list.addItem(um);
				}
			}
			
			msg.message_type = JSONUti.getChild(data, "message_type");
			
			var prop:Object = JSONUti.getChild(data, "system_message_properties");
			if(prop)
			{
				msg.subtype = JSONUti.getChild(prop, "subtype") as String;
			}
			
			return msg;
		}
		
		private function loadAttachments(data:Object):void
		{
			if(!data){ return; }
			
			attachments = new ArrayCollection();
			for each(var attachment_data:Object in data)
			{
				hasAttachments = true;
				var att:AttachmentModel = new AttachmentModel();
				att.downloadUrl = JSONUti.getChild(attachment_data, "download_url");
				att.filename = JSONUti.getChild(attachment_data, "name");
				attachments.addItem(att);
			}
		}
	}
}