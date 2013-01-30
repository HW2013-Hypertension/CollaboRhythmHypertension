package collaboRhythm.shared.model.healthRecord.document
{

	import collaboRhythm.shared.model.healthRecord.*;

	[Bindable]
	public class Wellness extends DocumentBase
	{
		public static const DOCUMENT_TYPE:String = "http://indivo.org/vocab/xml/documents#Wellness";

		private var _measurementDate:Date;
		private var _reportedBy:String;
		private var _dateReported:Date;
		private var _numberOfStepsTaken:int;
		private var _numberOfHoursSlept:Number;
		private var _numberOfTimesAwakened:int;

		private var _triggeredHealthActionResults:Vector.<HealthActionResult> = new Vector.<HealthActionResult>();

		public function Wellness( measurementDate:Date = null, reportedBy:String = null, dateReported:Date = null, numberOfStepsTaken:int = 0, numberOfHoursSlept:Number = NaN, numberOfTimesAwakened:int = 0)
		{
			meta.type = DOCUMENT_TYPE;
			_measurementDate = measurementDate;
			_reportedBy = reportedBy;
			_dateReported = dateReported;
			_numberOfStepsTaken = numberOfStepsTaken;
			_numberOfHoursSlept = numberOfHoursSlept;
			_numberOfTimesAwakened = numberOfTimesAwakened;
		}

		public function get measurementDate():Date
		{
			return _measurementDate;
		}

		public function set measurementDate(value:Date):void
		{
			_measurementDate = value;
		}

		public function get reportedBy():String
		{
			return _reportedBy;
		}

		public function set reportedBy(value:String):void
		{
			_reportedBy = value;
		}

		public function get dateReported():Date
		{
			return _dateReported;
		}

		public function set dateReported(value:Date):void
		{
			_dateReported = value;
		}

		public function get numberOfStepsTaken():int
		{
			return _numberOfStepsTaken;
		}
		
		public function set numberOfStepsTaken(value:int):void
		{
			_numberOfStepsTaken = value;
		}

		public function get numberOfHoursSlept():Number
		{
			return _numberOfHoursSlept;
		}

		public function set numberOfHoursSlept(value:Number):void
		{
			_numberOfHoursSlept = value;
		}

		public function get numberOfTimesAwakened():int
		{
			return _numberOfTimesAwakened;
		}

		public function set numberOfTimesAwakened(value:int):void
		{
			_numberOfTimesAwakened = value;
		}

		public function get triggeredHealthActionResults():Vector.<HealthActionResult>
		{
			return _triggeredHealthActionResults;
		}

		public function set triggeredHealthActionResults(value:Vector.<HealthActionResult>):void
		{
			_triggeredHealthActionResults = value;
		}
	}
}
