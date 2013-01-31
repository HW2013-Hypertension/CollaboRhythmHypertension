package collaboRhythm.plugins.schedule.shared.controller
{
	import collaboRhythm.ane.applicationMessaging.actionScript.ApplicationMessaging;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputModel;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;

	import flash.net.URLVariables;

	import flash.system.Capabilities;

	public class HealthActionInputControllerBase
	{
		public static const BATCH_TRANSFER_URL_VARIABLE:String = "batchTransfer";
		public static const BATCH_TRANSFER_ACTION_END:String = "end";
		public static const BATCH_TRANSFER_ACTION_BEGIN:String = "begin";

		public function HealthActionInputControllerBase()
		{
		}

		public function handleAdherenceChange(dataInputModel:IHealthActionInputModel,
									   scheduleItemOccurrence:ScheduleItemOccurrence, selected:Boolean):void
		{
		}

		public function get isReview():Boolean
		{
			return false;
		}

		/**
		 * Sends a broadcast message to CollaboRhythm.Android.DeviceGateway (or any listening applications on Android)
		 * indicating that a duplicate has been received. Only sends when not debugging and when on the device (not
		 * desktop).
		 */
		protected static function safeSendBroadcastDuplicateDetected():void
		{
			if (Capabilities.playerType == "Desktop" && Capabilities.isDebugger)
			{
			}
			else
			{
				sendBroadcastDuplicateDetected();
			}
		}

		private static function sendBroadcastDuplicateDetected():void
		{
			var extension:ApplicationMessaging = new ApplicationMessaging();
			extension.sendBroadcast("CollaboRhythm-health-action-received-v1", "duplicate",
					"healthActionStringTest1");
		}

		public function shouldIgnoreUrlVariables(urlVariables:URLVariables):Boolean
		{
			return false;
		}
	}
}
