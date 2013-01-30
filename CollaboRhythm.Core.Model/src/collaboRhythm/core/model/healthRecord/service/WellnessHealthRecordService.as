package collaboRhythm.core.model.healthRecord.service
{

	import collaboRhythm.core.model.healthRecord.Schemas;
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.*;
	import collaboRhythm.shared.model.healthRecord.document.Wellness;

	import org.indivo.client.IndivoClientEvent;

	public class WellnessHealthRecordService extends DocumentStorageSingleReportServiceBase
	{
		public function WellnessHealthRecordService(consumerKey:String, consumerSecret:String, baseURL:String,
														   account:Account, debuggingToolsEnabled:Boolean)
		{
			super(consumerKey, consumerSecret, baseURL, account, debuggingToolsEnabled, Wellness.DOCUMENT_TYPE,
				  Wellness, Schemas.WellnessSchema, "Wellness");
		}

		override protected function documentShouldBeIncluded(document:IDocument, nowTime:Number):Boolean
		{
			var wellness:Wellness = document as Wellness;
			return wellness.measurementDate == null || wellness.measurementDate.valueOf() <= nowTime;
		}

		override protected function updateModelAfterHandleReportResponse(event:IndivoClientEvent, responseXml:XML,
																		 healthRecordServiceRequestDetails:HealthRecordServiceRequestDetails):void
		{
			var i:int;
			super.updateModelAfterHandleReportResponse(event, responseXml, healthRecordServiceRequestDetails);
			_logger.debug("Wellness documents " + activeAccount.primaryRecord.wellnessModel.documents.length);

		}

	}
}