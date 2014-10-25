package com.kikijiki.nyammer.async
{
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.UserModel;

	public class AsyncUserLoadTask extends AsyncTask
	{
		private var user:UserModel;
		private var loadCallback:Function;
		
		public function AsyncUserLoadTask(network:NetworkModel, user:UserModel, callback:Function)
		{
			this.user = user;
			loadCallback = callback;
			this.task = function():void
			{
				network.updateUserModel(user, function(success:Boolean, user:UserModel):void
				{
					loadCallback(success, user);
					finished();
				});
			}
		}

		override public function get id():String
		{
			return user.id;
		}
	}
}