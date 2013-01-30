package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;

	public class WellnessChartDescriptor implements IChartDescriptor
	{
		public function WellnessChartDescriptor()
		{
		}

		public function get descriptorKey():String
		{
			return "wellness";
		}
	}
}
