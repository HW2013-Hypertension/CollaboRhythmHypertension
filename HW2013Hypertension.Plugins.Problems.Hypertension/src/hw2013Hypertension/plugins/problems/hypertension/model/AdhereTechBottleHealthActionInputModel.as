package hw2013Hypertension.plugins.problems.hypertension.model
{
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.plugins.schedule.shared.model.IScheduleCollectionsProvider;
	import collaboRhythm.shared.model.DateUtil;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.CollaboRhythmCodedValue;
	import collaboRhythm.shared.model.healthRecord.CollaboRhythmValueAndUnit;
	import collaboRhythm.shared.model.healthRecord.DocumentBase;
	import collaboRhythm.shared.model.healthRecord.document.AdherenceItem;
	import collaboRhythm.shared.model.healthRecord.document.MedicationAdministration;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import flash.net.URLVariables;

	public class AdhereTechBottleHealthActionInputModel
	{
		private var _scheduleItemOccurrence:ScheduleItemOccurrence;
		private var _healthActionModelDetailsProvider:IHealthActionModelDetailsProvider;
		private var _record:Record;
		private var _scheduleCollectionsProvider:IScheduleCollectionsProvider;
		private var _currentDateSource:ICurrentDateSource;

		public function AdhereTechBottleHealthActionInputModel(scheduleItemOccurrence:ScheduleItemOccurrence,
															   healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
															   scheduleCollectionsProvider:IScheduleCollectionsProvider)
		{
			_scheduleItemOccurrence = scheduleItemOccurrence;
			_healthActionModelDetailsProvider = healthActionModelDetailsProvider;
			_scheduleCollectionsProvider = scheduleCollectionsProvider;

			_record = _healthActionModelDetailsProvider.record;

			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;
		}

		public function handleUrlVariable(urlVariables:URLVariables):void
		{
//			var ndcCode:String = urlVariables.ndcCode;

			var scheduleItemOccurrence:ScheduleItemOccurrence = _scheduleCollectionsProvider.findClosestScheduleItemOccurrence("Hydrochlorothiazide 25 MG Oral Tablet", DateUtil.format(_currentDateSource.now()));

			var adherenceItem:AdherenceItem = new AdherenceItem();
			adherenceItem.name = scheduleItemOccurrence.scheduleItem.name;
			adherenceItem.reportedBy = _healthActionModelDetailsProvider.accountId;
			adherenceItem.dateReported = _currentDateSource.now();
			adherenceItem.recurrenceIndex = scheduleItemOccurrence.recurrenceIndex;
			adherenceItem.adherence = true;

			var medicationAdministration:MedicationAdministration = new MedicationAdministration();
			medicationAdministration.name = adherenceItem.name;
			medicationAdministration.reportedBy = _healthActionModelDetailsProvider.accountId;
			medicationAdministration.dateReported = _currentDateSource.now();
			medicationAdministration.dateAdministered = _currentDateSource.now();
			medicationAdministration.amountAdministered = new CollaboRhythmValueAndUnit("1", new CollaboRhythmCodedValue(null, null, null, "tablet"), "1");

			var adherenceResults:Vector.<DocumentBase> = new Vector.<DocumentBase>();
			adherenceResults.push(medicationAdministration);

			scheduleItemOccurrence.createAdherenceItem(adherenceResults, _record, _healthActionModelDetailsProvider.accountId, true);
		}
	}
}
