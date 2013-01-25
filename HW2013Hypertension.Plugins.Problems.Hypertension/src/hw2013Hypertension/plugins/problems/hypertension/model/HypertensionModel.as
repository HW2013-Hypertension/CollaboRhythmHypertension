package hw2013Hypertension.plugins.problems.hypertension.model
{
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.DocumentBase;
	import collaboRhythm.shared.model.healthRecord.document.AdherenceItem;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionSchedule;
	import collaboRhythm.shared.model.healthRecord.document.VitalSign;
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
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
		private var _messages:ArrayCollection = new ArrayCollection();

		private var _currentDateSource:ICurrentDateSource;

		public function HypertensionModel(activeRecordAccount:Account)
		{

			super();

			_record = activeRecordAccount.primaryRecord;

			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;

			_healthActionScheduleCollection = _record.healthActionSchedulesModel.healthActionScheduleCollection;
//			BindingUtils.bindSetter(healthActionSchedulesModel_isStitchedHandler, _record.healthActionSchedulesModel, "isStitched");

			BindingUtils.bindSetter(record_isLoading, _record, "isLoading");
		}

		private function record_isLoading(isLoading:Boolean):void
		{
			if (!isLoading)
			{
				calculatePercentAdherence();
				calculateScore();
			}
		}

		private function calculateScore():void
		{
			var score:int = 0;

			for each (var healthActionSchedule:HealthActionSchedule in _healthActionScheduleCollection)
			{
				if (healthActionSchedule.name.text == BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE)
				{
					var dateWeekEnd:Date = _currentDateSource.now();
					var dateWeekStart:Date = new Date(dateWeekEnd.time - NUMBER_OF_MILLISECONDS_IN_WEEK * 2);

					for each (var adherenceItem:AdherenceItem in healthActionSchedule.adherenceItems)
					{
						if (adherenceItem.dateReported.time > dateWeekStart.time &&
								adherenceItem.dateReported.time < dateWeekEnd.time)
						{
							var adherenceResults:Vector.<DocumentBase> = adherenceItem.adherenceResults;

							if (adherenceResults.length != 0)
							{
								var systolic:Number;
								var diastolic:Number;

								for each (var adherenceResult:DocumentBase in adherenceResults)
								{
									var vitalSign:VitalSign = adherenceResult as VitalSign;
									if (vitalSign)
									{

										if (vitalSign.name.text == VitalSignsModel.SYSTOLIC_CATEGORY)
										{
											systolic = vitalSign.resultAsNumber;
										}
										else if (vitalSign.name.text == VitalSignsModel.DIASTOLIC_CATEGORY)
										{
											diastolic = vitalSign.resultAsNumber;
										}
									}
								}

								if (systolic < 140 && diastolic < 90)
								{
									score = score + 2;
								}
								else if (systolic < 140 || diastolic < 90)
								{
									score = score + 1;
								}

							}
						}
					}
				}
			}
			_messages.addItem("Congratulations, your score was " + score.toString());
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
						if (adherenceItem.dateReported.time > dateWeekStart.time &&
								adherenceItem.dateReported.time < dateWeekEnd.time)
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

		public function get messages():ArrayCollection
		{
			return _messages;
		}
	}
}
