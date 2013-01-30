package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSign;
	import collaboRhythm.shared.model.healthRecord.document.Wellness;

	public class StepsPerDayProxy
	{
		private var _wellness:Wellness;
		private var _vitalSign:VitalSign;

		public function StepsPerDayProxy(wellness:Wellness)
		{
			_wellness = wellness;
		}

		public function get wellness():Wellness
		{
			return _wellness;
		}

		public function get measurementDate():Date
		{
			return wellness.measurementDate;
		}

		public function get radius():Number
		{
			return wellness.numberOfStepsTaken / 100.0;
		}

		public function set vitalSign(vitalSign:VitalSign):void
		{
			_vitalSign = vitalSign;
		}

		public function get systolic():Number
		{
			if(_vitalSign === undefined || _vitalSign === null)
			{
				return NaN;
			}
			return _vitalSign.resultAsNumber;

			//return _vitalSign ?_vitalSign.resultAsNumber : NaN;
		}
	}
}
