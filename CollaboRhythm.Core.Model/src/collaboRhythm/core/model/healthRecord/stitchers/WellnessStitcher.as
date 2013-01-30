package collaboRhythm.core.model.healthRecord.stitchers
{
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.IDocument;
	import collaboRhythm.shared.model.healthRecord.Relationship;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionResult;
	import collaboRhythm.shared.model.healthRecord.document.Wellness;

	public class WellnessStitcher extends DocumentStitcherBase
	{
		public function WellnessStitcher(record:Record)
		{
			super(record, Wellness.DOCUMENT_TYPE);
			addRequiredDocumentType(HealthActionResult.DOCUMENT_TYPE);
		}

		override protected function stitchSpecialReferencesOnDocument(document:IDocument):void
		{
			var wellness:Wellness = document as Wellness;
			for each (var triggeredHealthActionResultRelationship:Relationship in wellness.relatesTo)
			{
				var triggeredHealthActionResult:HealthActionResult = triggeredHealthActionResultRelationship.relatesTo as HealthActionResult;
				if (triggeredHealthActionResult)
				{
					wellness.triggeredHealthActionResults.push(triggeredHealthActionResult);
				}
			}
		}
	}
}
