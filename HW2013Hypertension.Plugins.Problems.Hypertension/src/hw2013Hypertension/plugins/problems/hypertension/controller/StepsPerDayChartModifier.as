package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.ChartModifierBase;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;

	import com.dougmccune.controls.ScrubChart;
	import com.dougmccune.controls.SeriesDataSet;
	import com.theory9.data.types.OrderedMap;

	import mx.charts.chartClasses.CartesianChart;
	import mx.charts.series.BubbleSeries;
	import mx.charts.series.PlotSeries;
	import mx.collections.ArrayCollection;
	import mx.core.IVisualElement;
	import mx.graphics.SolidColor;
	import mx.graphics.SolidColorStroke;

	import qs.charts.dataShapes.DataDrawingCanvas;

	import spark.components.Label;

	public class StepsPerDayChartModifier extends ChartModifierBase implements IChartModifier
	{
		public function StepsPerDayChartModifier(wellnessChartDescriptor:IChartDescriptor,
												 chartModelDetails:IChartModelDetails,
												 decoratedChartModifier:IChartModifier)
		{
			super(wellnessChartDescriptor, chartModelDetails, decoratedChartModifier);
		}

		public function modifyCartesianChart(chart:ScrubChart, cartesianChart:CartesianChart, isMainChart:Boolean):void
		{
		}

		public function createMainChartSeriesDataSets(chart:ScrubChart,
													  seriesDataSets:Vector.<SeriesDataSet>):Vector.<SeriesDataSet>
		{
			var vitalSignSeries:BubbleSeries;
			var seriesDataCollection:ArrayCollection;

			vitalSignSeries = new BubbleSeries();
			vitalSignSeries.name = "systolic";
			vitalSignSeries.id = chart.id + "_systolicSeries";
			vitalSignSeries.xField = "dateMeasuredStart";
			vitalSignSeries.yField = "resultAsNumber";
			vitalSignSeries.radiusField = "resultAsNumber";
			seriesDataCollection = chartModelDetails.record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.SYSTOLIC_CATEGORY);
			vitalSignSeries.dataProvider = seriesDataCollection;
			vitalSignSeries.displayName = "Blood Pressure Systolic";
			vitalSignSeries.filterDataValues = "none";
			vitalSignSeries.setStyle("stroke", new SolidColorStroke(0x224488, 2));
			vitalSignSeries.setStyle("fill", new SolidColor(0xFF0000));
			seriesDataSets.push(new SeriesDataSet(vitalSignSeries, seriesDataCollection, "dateMeasuredStart"));

			return seriesDataSets;
		}

		public function createImage(currentChartImage:IVisualElement):IVisualElement
		{
			return null;
		}

		public function drawBackgroundElements(canvas:DataDrawingCanvas, zoneLabel:Label):void
		{
		}

		public function updateChartDescriptors(chartDescriptors:OrderedMap):OrderedMap
		{
			return chartDescriptors;
		}
	}
}
