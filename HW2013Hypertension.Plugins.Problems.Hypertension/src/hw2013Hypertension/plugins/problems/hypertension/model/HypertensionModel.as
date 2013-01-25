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
			var totalreadings:int = 0;
			var goodreadings:int = 0;
			var totalscore:int = 0;


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
							totalreadings= totalreadings +1;
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
									goodreadings= goodreadings +1;
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
			 totalscore= (goodreadings/totalreadings)*0.75 +0.25;

			if (totalreadings < 6)
			{
				_messages.addItem("Having a high blood pressure, but not knowing about it, can be really"+
						      "\n"+"dangerous.This is why they call high blood pressure 'The Silent Killer'."+
						      "\n"+"To know how your blood pressure is doing make sure to take at least 3"+
						      "\n"+"readings per week!" );
			}

			else
			{

				 if(totalscore>= 65)
				{
					_messages.addItem("Great job, you are taking control of your blood pressure, and your"+
									"\n"+"own health. Keep up the good work and enjoy a pressure free life.");
				}
				else
				{
					_messages.addItem("It is good that you are measuring your blood pressure on a regular basis"+
									  "\n"+"That is the first and foremost step towards a pressure free life." +
									  "\n"+"Continue to eat well, sleep well, exercise and adhere to your drug" +
									  "\n"+"regimen, and you should see your blood pressure drop accordingly. If"+
									  "\n"+"not, make sure to consult your local pharmacy, as different"+
									  "\n"+"treatmeant might be better suited to you" );
				}
			}
			/*if (score > 0.75*28)
			{
				_messages.addItem("Congratulations, your score was " + score.toString()+
						           "\n"+"you have your blood pressure well under control");
			}
			else if(0.50*28<score<=0.75*28)
			{
				_messages.addItem("It is difficult to tell whether your blood pressure is under control," +
							       "\n"+"remember to take at least 3 measurements per week");
			}
			else
			{
				_messages.addItem("Your blood pressure levels are higher than they should be. Remember to exercise, " +
						 "\n"+"eat well, sleep well and adhere to your regiman ")
			}*/

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
