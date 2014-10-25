package com.kikijiki.nyammer.models
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import com.kikijiki.nyammer.views.UserIcon;
	
	import mx.core.BitmapAsset;

	[Bindable]
	public class UserModel
	{
		public var data:Object;
		
		public var id:String;
		public var online:Boolean = false;
		public var name:String;
		public var fullName:String;
		public var job:String;
		public var icon_url:String;
		public var icon:BitmapData;
		public var mail:String;
		
		public var network:NetworkModel;
		
		public function UserModel(network:NetworkModel):void
		{
			this.network = network;
		}
		
		public function updateData(data:Object):void
		{
			this.data = data;
			id = data["id"];
			name = data["name"];
			fullName = data["first_name"];
			job = data["last_name"];
			icon_url = data["mugshot_url"];
			mail = data["contact"]["email_addresses"][0]["address"];
		}
		
		public static function parseUser(data:Object, network:NetworkModel):UserModel
		{
			var user:UserModel = new UserModel(network);
			user.updateData(data);
			return user;
		}
		
		public function toString():String
		{
			return fullName + "(" + job + ")";
		}
		
		public function setIcon(target:UserIcon):void
		{
			network.users.setIcon(this, target);
		}
		
		public static function isValid(user:UserModel = null):Boolean
		{
			if(user == null){ return false; }
			if(user.id == null){ return false; }
			if(user.id.length == 0){ return false; }
			
			return true
		}
	}
}