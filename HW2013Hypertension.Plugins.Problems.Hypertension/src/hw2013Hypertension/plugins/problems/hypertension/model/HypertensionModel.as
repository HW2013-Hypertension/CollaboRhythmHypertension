package hw2013Hypertension.plugins.problems.hypertension.model
{
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.DocumentBase;
	import collaboRhythm.shared.model.healthRecord.document.AdherenceItem;
	import collaboRhythm.shared.model.healthRecord.document.HealthActionSchedule;
	import collaboRhythm.shared.model.healthRecord.document.MedicationScheduleItem;
	import collaboRhythm.shared.model.healthRecord.document.VitalSign;
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import flash.sampler.getSampleCount;

	import flashx.textLayout.formats.ClearFloats;

	import mx.binding.utils.BindingUtils;

	import mx.collections.ArrayCollection;
	import mx.formatters.NumberBase;
	import mx.formatters.NumberBaseRoundType;

	[Bindable]
	public class HypertensionModel
	{

		private static const BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE:String = "FORA D40b";
		private static const NUMBER_OF_MILLISECONDS_IN_REWARD_SCORE_DURATION:Number = 1000 * 60 * 60 * 24 * REWARD_SCORE_DURATION;
		private static const REWARD_SCORE_DURATION:int = 7;


		private var _record:Record;
		private var _healthActionScheduleCollection:ArrayCollection;
		private var _medicationScheduleItemCollection:ArrayCollection;
		private var _percentBloodPressureAdherence:int;
		private var _rewardScore:int;
		private var _perfectScore:int;
		private var _messages:ArrayCollection = new ArrayCollection();
		private var _messages1:ArrayCollection = new ArrayCollection();


		private var _messages2:ArrayCollection = new ArrayCollection();
		private var _messages3:ArrayCollection = new ArrayCollection();
		private var _currentDateSource:ICurrentDateSource;
		private var _mostRecentSystolic:Number;
		private var _mostRecentDiastolic:Number;
		private var _medicationSchedule:ArrayCollection;


		public function HypertensionModel(activeRecordAccount:Account)
		{

			super();

			_record = activeRecordAccount.primaryRecord;
			_medicationScheduleItemCollection = _record.medicationScheduleItemsModel.medicationScheduleItemCollection;


			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;

			_healthActionScheduleCollection = _record.healthActionSchedulesModel.healthActionScheduleCollection;
			_medicationSchedule = _record.medicationScheduleItemsModel.medicationScheduleItemCollection
// BindingUtils.bindSetter(healthActionSchedulesModel_isStitchedHandler, _record.healthActionSchedulesModel, "isStitched");

			BindingUtils.bindSetter(record_isLoading, _record, "isLoading");
		}

		private function record_isLoading(isLoading:Boolean):void
		{
			if (!isLoading)
			{
				calculatePercentAdherence();
				calculateScore();
				calculateWeekly();
			}
		}

		private function calculateScore():void
		{
			var score:int = 0;
			var totalreadings:int = 0;
			var goodreadings:int = 0;
			var totalscore:int = 0;
			var totalsystolic:int = 0;
			var totaldiastolic:int = 0;
			var averagesystolic:Number = 0;
			var averagediastolic:Number = 0;
			var count:int = 0;

			//var mostRecentDiastolic:Number;


			var systolicVitalSignsCollection:ArrayCollection = _record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.SYSTOLIC_CATEGORY);
			var diastolicVitalSignsCollection:ArrayCollection = _record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.DIASTOLIC_CATEGORY);

			if (systolicVitalSignsCollection && systolicVitalSignsCollection.length != 0)
			{
				var mostRecentSystolicVitalSign:VitalSign = systolicVitalSignsCollection.getItemAt(systolicVitalSignsCollection.length -
						1) as VitalSign;
				mostRecentSystolic = mostRecentSystolicVitalSign.resultAsNumber;
			}
			if (diastolicVitalSignsCollection && diastolicVitalSignsCollection.length != 0)
			{
				var mostRecentDiastolicVitalSign:VitalSign = diastolicVitalSignsCollection.getItemAt(diastolicVitalSignsCollection.length -
						1) as VitalSign;
				mostRecentDiastolic = mostRecentDiastolicVitalSign.resultAsNumber;
			}

			for each (var healthActionSchedule:HealthActionSchedule in _healthActionScheduleCollection)
			{
				if (healthActionSchedule.name.text == BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE)
				{
					var dateWeekEnd:Date = _currentDateSource.now();
					var dateWeekStart:Date = new Date(dateWeekEnd.time - NUMBER_OF_MILLISECONDS_IN_REWARD_SCORE_DURATION);

					for each (var adherenceItem:AdherenceItem in healthActionSchedule.adherenceItems)
					{
						totalreadings = totalreadings + 1;
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
									goodreadings = goodreadings + 1;
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
			totalscore = (goodreadings / totalreadings) * 0.75 + 0.25;

			if (totalreadings < 6)
			{
				_messages.addItem("Having a high blood pressure, but not knowing about it, can be really" +
						"\n" + "dangerous.This is why they call high blood pressure 'The Silent Killer'." +
						"\n" + "To know how your blood pressure is doing make sure to take at least" +
						"\n" + "3 readings per week!");
			}

			else
			{

				if (totalscore >= 65)
				{
					_messages.addItem("Great job, you are taking control of your blood pressure, and your" +
							"\n" + "own health. Keep up the good work and enjoy a pressure free life.");
				}
				else
				{
					_messages.addItem("It is good that you are measuring your blood pressure on a regular basis" +
							"\n" + "That is the first and foremost step towards a pressure free life. Continue" +
							"\n" + "to eat well, sleep well, exercise and adhere to your drug regimen, and" +
							"\n" + "you should see your blood pressure drop accordingly. If not, make sure" +
							"\n" + "to consult your local pharmacy, as different treatment might be better " +
							"\n" + "suited to you." + "");
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
			rewardScore = 0;

			var dateWeekEnd:Date = _currentDateSource.now();
			var dateWeekStart:Date = new Date(dateWeekEnd.time - NUMBER_OF_MILLISECONDS_IN_REWARD_SCORE_DURATION);
			var beginningOfToday:Date = new Date(_currentDateSource.now().fullYear, _currentDateSource.now().month,
					_currentDateSource.now().date);

			for each (var medicationScheduleItem:MedicationScheduleItem in _medicationScheduleItemCollection)
			{
				perfectScore = perfectScore += (100 * REWARD_SCORE_DURATION);

				for each (var adherenceItem:AdherenceItem in medicationScheduleItem.adherenceItems)
				{
					if (adherenceItem.dateReported.time > dateWeekStart.time &&
							adherenceItem.dateReported.time < dateWeekEnd.time)
					{
						if (adherenceItem.adherence)
						{
							rewardScore += 100;

							//if (adherenceItem.dateReported.time > beginningOfToday.time)
							//{
								_messages2.addItem("Your buddy earned 100 points because you took your" +
								"\n" + "medication today"+currentDateSource.currentDate+"");
							//}
						}
					}
				}
			}

			for each (var healthActionSchedule:HealthActionSchedule in _healthActionScheduleCollection)
			{
				if (healthActionSchedule.name.text == BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE)
				{
					perfectScore = perfectScore += (100 * REWARD_SCORE_DURATION);

					for each (var adherenceItem:AdherenceItem in healthActionSchedule.adherenceItems)
					{
						if (adherenceItem.dateReported.time > dateWeekStart.time &&
								adherenceItem.dateReported.time < dateWeekEnd.time)
						{
							if (adherenceItem.adherence)
							{
								rewardScore = rewardScore + 100;
								//if (adherenceItem.dateReported.time > beginningOfToday.time)
								//{
									_messages2.addItem("Your buddy earned 100 points because you took your blood pressure" +
											"\n" + adherenceItem.dateReported.time + "");
								//}
							}
						}
					}
				}
			}
			_messages1.addItem("Every time you take positive actions towards controlling your blood" +
					"\n" + "pressure, your buddy gets rewarded!"+"\n" +"\n" +"\n" );

			percentBloodPressureAdherence = adherenceCount / REWARD_SCORE_DURATION * 100;
		}

		private function calculateWeekly():void
		{
			var score:int = 0;
			var totalreadings:int = 0;
			var goodreadings:int = 0;
			var totalscore:int = 0;
			var totalsystolic:int = 0;
			var totaldiastolic:int = 0;
			var averagesystolic:int = 0;
			var averagediastolic:int = 0;
			var count:int = 0;

			//var mostRecentDiastolic:Number;


			var systolicVitalSignsCollection:ArrayCollection = _record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.SYSTOLIC_CATEGORY);
			var diastolicVitalSignsCollection:ArrayCollection = _record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.DIASTOLIC_CATEGORY);

			if (systolicVitalSignsCollection && systolicVitalSignsCollection.length != 0)
			{
				var mostRecentSystolicVitalSign:VitalSign = systolicVitalSignsCollection.getItemAt(systolicVitalSignsCollection.length -
						1) as VitalSign;
				mostRecentSystolic = mostRecentSystolicVitalSign.resultAsNumber;
			}
			if (diastolicVitalSignsCollection && diastolicVitalSignsCollection.length != 0)
			{
				var mostRecentDiastolicVitalSign:VitalSign = diastolicVitalSignsCollection.getItemAt(diastolicVitalSignsCollection.length -
						1) as VitalSign;
				mostRecentDiastolic = mostRecentDiastolicVitalSign.resultAsNumber;
			}

			for each (var healthActionSchedule:HealthActionSchedule in _healthActionScheduleCollection)
			{
				if (healthActionSchedule.name.text == BLOOD_PRESSURE_HEALTH_ACTION_SCHEDULE)
				{
					var dateWeekEnd:Date = _currentDateSource.now();
					var dateWeekStart:Date = new Date(dateWeekEnd.time - NUMBER_OF_MILLISECONDS_IN_REWARD_SCORE_DURATION);

					for each (var adherenceItem:AdherenceItem in healthActionSchedule.adherenceItems)
					{
						count = count + 1;

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
										totalsystolic = totalsystolic + systolic;
									}
									else if (vitalSign.name.text == VitalSignsModel.DIASTOLIC_CATEGORY)
									{
										diastolic = vitalSign.resultAsNumber;
										totaldiastolic = totaldiastolic + diastolic;
									}
								}
							}


						}
					}
				}
			}

			averagesystolic = totalsystolic / count;
			averagediastolic = totaldiastolic / count;
			if (averagediastolic > 60 && averagediastolic < 90 && averagesystolic > 90 && averagesystolic < 140)
			{
				_messages3.addItem("Congratulations your  average systolic this week was " + averagesystolic +
						" and your" +
						"\n" + "average diastolic was " + averagediastolic +
						". You are rewarded with a coupon for a free" +
						"\n" + "health check at the local pharmacy clinic.");
			}


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

		public function get currentDateSource():ICurrentDateSource
		{
			return _currentDateSource;
		}

		public function get mostRecentSystolic():Number
		{
			return _mostRecentSystolic;
		}

		public function set mostRecentSystolic(value:Number):void
		{
			_mostRecentSystolic = value;
		}

		public function get messages1():ArrayCollection
		{
			return _messages1;
		}

		public function set messages1(value:ArrayCollection):void
		{
			messages1 = value;
		}

		public function get mostRecentDiastolic():Number
		{
			return _mostRecentDiastolic;
		}

		public function set mostRecentDiastolic(value:Number):void
		{
			_mostRecentDiastolic = value;
		}

		public function get messages2():ArrayCollection
		{
			return _messages2;
		}

		public function set messages2(value:ArrayCollection):void
		{
			_messages2 = value;
		}

		public function get rewardScore():int
		{
			return _rewardScore;
		}

		public function set rewardScore(value:int):void
		{
			_rewardScore = value;
		}

		public function get messages3():ArrayCollection
		{
			return _messages3;
		}

		public function set messages3(value:ArrayCollection):void
		{
			_messages3 = value;
		}

		public function get perfectScore():int
		{
			return _perfectScore;
		}

		public function set perfectScore(value:int):void
		{
			_perfectScore = value;
		}
	}
}
