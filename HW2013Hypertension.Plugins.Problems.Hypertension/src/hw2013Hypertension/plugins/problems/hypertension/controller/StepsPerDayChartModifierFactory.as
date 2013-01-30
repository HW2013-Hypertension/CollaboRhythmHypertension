package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.VitalSignChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifierFactory;

	import com.theory9.data.types.OrderedMap;

	public class StepsPerDayChartModifierFactory implements IChartModifierFactory
	{
		public function StepsPerDayChartModifierFactory()
		{
		}

		public function createChartModifier(chartDescriptor:IChartDescriptor, chartModelDetails:IChartModelDetails,
											currentChartModifier:IChartModifier):IChartModifier
		{
			if (chartDescriptor is VitalSignChartDescriptor && (chartDescriptor as VitalSignChartDescriptor).vitalSignCategory == VitalSignsModel.STEP_COUNT_CATEGORY)
				return new StepsPerDayChartModifier(chartDescriptor, chartModelDetails, currentChartModifier);
			else
				return currentChartModifier;
		}

		public function updateChartDescriptors(chartDescriptors:OrderedMap):OrderedMap
		{
			var chartDescriptor:VitalSignChartDescriptor = new VitalSignChartDescriptor();
			chartDescriptor.vitalSignCategory = VitalSignsModel.STEP_COUNT_CATEGORY;
			if (chartDescriptors.getValueByKey(chartDescriptor.descriptorKey) == null)
			{
				chartDescriptors.addKeyValue(chartDescriptor.descriptorKey, chartDescriptor);
			}
			return chartDescriptors;
		}
	}
}
