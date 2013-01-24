package hw2013Hypertension.plugins.problems.hypertension.model
{
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.document.AdherenceItem;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionSchedule;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import mx.binding.utils.BindingUtils;

	import mx.collections.ArrayCollection;

	[Bindable]
	public class HypertensionModel
	{

		private static const BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE:String = "FORA D40b";
		private const NUMBER_OF_MILLISECONDS_IN_WEEK:Number = 1000 * 60 * 60 * 24 * 7;

		private var _record:Record;
		private var _healthActionScheduleCollection:ArrayCollection;
		private var _percentBloodPressureAdherence:int;

		private var _currentDateSource:ICurrentDateSource;

		public function HypertensionModel(activeRecordAccount:Account)
		{

			super();

			_record = activeRecordAccount.primaryRecord;

			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;

			_healthActionScheduleCollection =  _record.healthActionSchedulesModel.healthActionScheduleCollection;
			BindingUtils.bindSetter(healthActionSchedulesModel_isStitchedHandler, _record.healthActionSchedulesModel, "isStitched");
		}

		private function healthActionSchedulesModel_isStitchedHandler(isStitched:Boolean):void
		{
			if (isStitched)
			{
				calculatePercentAdherence();
			}
		}


		private function calculatePercentAdherence():void
		{
			var adherenceCount:int = 0;

			for each (var healthActionSchedule:HealthActionSchedule in _healthActionScheduleCollection)
			{
				if (healthActionSchedule.name.text == BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE)
				{
					var dateWeekEnd:Date = _currentDateSource.now();
					var dateWeekStart:Date = new Date(dateWeekEnd.time - NUMBER_OF_MILLISECONDS_IN_WEEK);

					for each (var adherenceItem:AdherenceItem in healthActionSchedule.adherenceItems)
					{
						if (adherenceItem.dateReported.time > dateWeekStart.time && adherenceItem.dateReported.time < dateWeekEnd.time)
						{
							adherenceCount++;
						}
					}
				}
			}

			percentBloodPressureAdherence = adherenceCount / 7 * 100;
		}

		public function get record():Record
		{
			return _record;
		}

		public function get percentBloodPressureAdherence():int
		{
			return _percentBloodPressureAdherence;
		}

		public function set percentBloodPressureAdherence(value:int):void
		{
			_percentBloodPressureAdherence = value;
		}
	}
}
