package collaboRhythm.core.model.healthRecord.service
{

	import collaboRhythm.core.model.healthRecord.Schemas;
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.*;
	import collaboRhythm.shared.model.healthRecord.document.Wellness;

	import org.indivo.client.IndivoClientEvent;
	import j2as3.collection.HashMap;

	public class WellnessHealthRecordService extends DocumentStorageSingleReportServiceBase
	{
		protected var _measurementDateMap:HashMap = new HashMap();

		public function WellnessHealthRecordService(consumerKey:String, consumerSecret:String, baseURL:String,
														   account:Account, debuggingToolsEnabled:Boolean)
		{
			super(consumerKey, consumerSecret, baseURL, account, debuggingToolsEnabled, Wellness.DOCUMENT_TYPE,
				  Wellness, Schemas.WellnessSchema, "Wellness");
		}

		override protected function documentShouldBeIncluded(document:IDocument, nowTime:Number):Boolean
		{
		/*
			This is an overridden method. This method will de-duplicate the data to ensure that for any given measurementDate,
			you have only one data point available.

			Check whether there is data for a specific date. If yes, then ignore record. else add this into HashMap and use the record.

			NOTE: The assumption here is that we get the data in the order of the document creations i.e. Latest Document first.

		 */
				var wellness:Wellness = document as Wellness;
			//return wellness.measurementDate.valueOf() <= nowTime;

			if (_measurementDateMap.getItem(wellness.measurementDate.toDateString()) == null)
			{
				_measurementDateMap.put( wellness.measurementDate.toDateString(), wellness.measurementDate.toDateString());
				_logger.debug("Wellness Measurement Date - " + wellness.measurementDate + "Wellness Steps - " + wellness.numberOfStepsTaken);
				return true;
			}
			else
			{
				_logger.debug("Ignored Wellness Measurement Date - " + wellness.measurementDate + "Wellness Steps - " + wellness.numberOfStepsTaken);
				return false;
			}
		}

		override protected function updateModelAfterHandleReportResponse(event:IndivoClientEvent, responseXml:XML,
																		 healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):void
		{
			var i:int;
			super.updateModelAfterHandleReportResponse(event, responseXml, healthRecordServiceRequestDetails);
			_logger.debug("Wellness documents " + activeAccount.primaryRecord.wellnessModel.documents.length);

			for (i=0;i<activeAccount.primaryRecord.wellnessModel.documents.length;i++){
				var wellness:Wellness = activeAccount.primaryRecord.wellnessModel.documents[i] as Wellness;
				_logger.debug("Wellness Measurement Date - " + wellness.measurementDate + "Wellness Steps - " + wellness.numberOfStepsTaken);
			}

			/*
				Resetting the HashMap to enable for Reload operation. When a reload button is pressed by the user, then new
				data needs to be reloaded and ignoring old data.
			*/
			_measurementDateMap = new HashMap();


		}


	}
}