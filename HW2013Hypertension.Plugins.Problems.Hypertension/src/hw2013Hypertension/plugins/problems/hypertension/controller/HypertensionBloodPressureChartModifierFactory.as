package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.VitalSignChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifierFactory;

	import com.theory9.data.types.OrderedMap;

	public class HypertensionBloodPressureChartModifierFactory implements IChartModifierFactory
	{
		public function HypertensionBloodPressureChartModifierFactory()
		{
		}

		public function createChartModifier(chartDescriptor:IChartDescriptor, chartModelDetails:IChartModelDetails,
											currentChartModifier:IChartModifier):IChartModifier
		{
			if (chartDescriptor is VitalSignChartDescriptor &&
					(chartDescriptor as VitalSignChartDescriptor).vitalSignCategory ==
							VitalSignsModel.SYSTOLIC_CATEGORY)
				return new HypertensionBloodPressureChartModifier(chartDescriptor as VitalSignChartDescriptor, chartModelDetails, currentChartModifier);
			else
				return currentChartModifier;
		}

		public function updateChartDescriptors(chartDescriptors:OrderedMap):OrderedMap
		{
			return null;
		}
	}
}
