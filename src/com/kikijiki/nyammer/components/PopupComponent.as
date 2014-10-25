package com.kikijiki.nyammer.components
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.media.StageWebView;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import com.kikijiki.nyammer.events.ThreadNewParticipantEvent;
	import com.kikijiki.nyammer.events.ThreadUpdatedEvent;
	import com.kikijiki.nyammer.models.MessageModel;
	import com.kikijiki.nyammer.models.NetworkModel;
	import com.kikijiki.nyammer.models.ThreadModel;
	import com.kikijiki.nyammer.views.ParticipantsView;
	import com.kikijiki.nyammer.windows.MarkMessageAsReadWindow;
	import com.kikijiki.nyammer.windows.PopupWindow;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.controls.Alert;
	import mx.controls.ProgressBar;
	import mx.effects.Sequence;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.IFocusManagerComplexComponent;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ObjectProxy;
	import mx.utils.StringUtil;
	
	import spark.components.Button;
	import spark.components.List;
	import spark.components.TextArea;
	import spark.components.Window;
	import spark.core.NavigationUnit;
	import spark.effects.Animate;
	import spark.effects.animation.Animation;
	import spark.events.TextOperationEvent;
	
	[Bindable]
	public class PopupComponent extends Window
	{
		public const INITIAL_SHOWN_REPLIES_COUNT:int = 5;
		
		public var btnOpen:Button;
		public var txtReplyBody:TextArea;
		public var lstThread:ScrollableList;
		
		private var forceClose:Boolean = false;
		
		public var loading:Boolean = false;
		public var thread:ThreadModel;
		public var replies:ListCollectionView;
		public var shown_replies:int;
		public var replyBody:String = "";
		public var replyToId:String;
		public var canReply:Boolean = false;
		public var unread:Number = 1;
		public var notificationAnimation:Animate;
		public var newParticipant:Animate;
		public var newParticipantLoop:Animate;
		public var lstParticipants:ParticipantsView;
		
		private var _network:NetworkModel;
		
		public function set network(v:NetworkModel):void
		{
			if(_network != v)
			{
				_network = v;
				onNetworkPlugged();
			}
		}
		
		public function get network():NetworkModel
		{
			return _network;
		}
		
		private function onNetworkPlugged():void
		{
			
		}
		
		public function PopupComponent()
		{
			super();

			addEventListener(FlexEvent.CREATION_COMPLETE, function():void
			{
				txtReplyBody.addEventListener(TextOperationEvent.CHANGE, function(event:Event):void
				{
					canReply = replyBody.length > 0;
				});
			});
			
			var popup:PopupComponent = this;
			
			addEventListener(Event.CLOSING, function(closingEvent:Event):void
			{
				if(forceClose){ return; }
				if(StringUtil.trim(replyBody).length == 0){ return; }
				closingEvent.preventDefault();
				
				Alert.buttonWidth = 80;
				Alert.show("メッセージは投稿されませんでした。また、下書きも保存されません。", "確認", Alert.OK | Alert.CANCEL, popup, function(alertEvent:CloseEvent):void
				{
					if(alertEvent.detail == Alert.OK)
					{
						forceClose = true;
						close();
					}
				});
			});
		}
		
		public function showThread():void
		{
			currentState = "shown";
			thread.markAsRead();
			callLater(function():void
			{
				if(replies){ replies.refresh(); }
				lstThread.scrollToBottom();
				txtReplyBody.setFocus();
			});
			
			thread.unreadCount = 0;
			newParticipantLoop.stop();
		}
		
		public function send():void
		{
			this.enabled = false;
			var popup:Window = this;
			
			var progressBar:ProgressBar = new ProgressBar();
			progressBar.width = 200;
			progressBar.indeterminate = true;
			progressBar.labelPlacement = "center";
			progressBar.setStyle("removedEffect", "fade");
			progressBar.setStyle("addedEffect", "fade");
			progressBar.setStyle("color", 0x000000);
			progressBar.setStyle("borderColor", 0x000000);
			progressBar.setStyle("barColor", 0xf4b60f);
			progressBar.label = "送信中…";
			
			PopUpManager.addPopUp(progressBar,　this,　true);
			PopUpManager.centerPopUp(progressBar);

			network.replyToMessage(thread.getReplyToId(), replyBody,
				function(success:Boolean, data:Object):void
				{
					if(success)
					{
						replyBody = "";
						callLater(txtReplyBody.setFocus);
						callLater(lstThread.scrollToBottom);
						canReply = false;
						thread.refresh();
					}
					else
					{
						var error:String = "Error code: " + (data as FaultEvent).statusCode;
						Alert.show("送信できませんでした。\n" + error, "注意", Alert.OK, popup);
					}
					
					popup.enabled = true;
					progressBar.visible = false;
					PopUpManager.removePopUp(progressBar);
				}
			);
		}
		
		public function load(thread:ThreadModel):void
		{
			this.thread = thread;
			this.network = thread.network;
			addEventListener(Event.CLOSING, function():void
			{
				network.popups[thread.id] = null;
			});
			
			this.replies = thread.createDataView();
			thread.preload(prepareList);
			shown_replies = INITIAL_SHOWN_REPLIES_COUNT;
			network.popups[thread.id] = this;
			thread.addEventListener("threadUpdatedEvent", function(event:ThreadUpdatedEvent):void
			{
				if(shown_replies > 0){ shown_replies++; }
				
				if(!visible || currentState == "hidden")
				{
					notificationAnimation.play();
					unread++;
				}
				else
				{
					if(replies != null){ replies.refresh(); }
					thread.unreadCount = 0;
					thread.markAsRead();
				}
			});
			thread.addEventListener("threadNewParticipant", function(event:ThreadNewParticipantEvent):void
			{
				if(currentState == "hidden")
				{
					newParticipantLoop.play();
				}
				else
				{
					newParticipant.play();
				}
			});
			thread.refresh();
		}
		
		private function prepareList():void
		{
			replies.filterFunction = function(msg:Object):Boolean
			{
				if(thread.initialMessage && msg.id == thread.initialMessage.id){ return false; }
				if(shown_replies < 0){ return true; }
				
				var index:int = thread.messages.getItemIndex(msg);
				var min_index:int = thread.messages.length - shown_replies;
				return index >= min_index;
			};
			replies.refresh();
			if(lstThread){ lstThread.scrollToBottom(); }
		}
		
		public function openInBrowser():void
		{
			navigateToURL(new URLRequest(thread.url), "_blank");
			close();
		}
		
		public function isShown():Boolean
		{
			return currentState == "shown";
		}
		
		public function showAllReplies():void
		{
			if(replies == null){ return; }
			
			shown_replies = -1;
			replies.refresh();
			
			if(!thread.complete)
			{
				loading = true;
				thread.retrieveAllMessages(function(success:Boolean):void
				{
					loading = false;
				});
			}
		}
	}
}