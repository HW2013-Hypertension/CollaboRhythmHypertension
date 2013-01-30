package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.DateUtil;
	import collaboRhythm.shared.model.healthRecord.document.VitalSign;
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.model.healthRecord.document.Wellness;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.ChartModifierBase;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;

	import com.dougmccune.controls.ScrubChart;
	import com.dougmccune.controls.SeriesDataSet;
	import com.theory9.data.types.OrderedMap;

	import mx.charts.HitData;

	import mx.charts.LinearAxis;

	import mx.charts.chartClasses.CartesianChart;
	import mx.charts.chartClasses.Series;
	import mx.charts.series.BubbleSeries;
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
			if (decoratedModifier)
				decoratedModifier.modifyCartesianChart(chart, cartesianChart, isMainChart);
			chart.mainChartTitle = "Blood Pressure (mmHg)";

/*
			var verticalAxis:LinearAxis = cartesianChart.verticalAxis as LinearAxis;
			verticalAxis.minimum = BLOOD_PRESSURE_VERTICAL_AXIS_MINIMUM;
			verticalAxis.maximum = BLOOD_PRESSURE_VERTICAL_AXIS_MAXIMUM;
*/

			cartesianChart.dataTipFunction = stepsPerDayChart_dataTipFunction;
		}

		private function stepsPerDayChart_dataTipFunction(hitData:HitData):String
		{
			var proxy:StepsPerDayProxy = hitData.item as StepsPerDayProxy;
			if (proxy)
			{
				return (hitData.chartItem.element as Series).displayName + "<br/>" +
						"<b>" + proxy.wellness.numberOfStepsTaken + "</b> (" + proxy.wellness.numberOfHoursSlept + " hours slept)<br/>" +
						"Systolic: " + proxy.systolic + " (mmHg)<br/>" +
						"Date measured: " + proxy.measurementDate.toLocaleString();
			}
			return hitData.displayText;
		}

		public function createMainChartSeriesDataSets(chart:ScrubChart,
													  seriesDataSets:Vector.<SeriesDataSet>):Vector.<SeriesDataSet>
		{
			var systolicCollection:ArrayCollection = chartModelDetails.record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.SYSTOLIC_CATEGORY);
			var wellnessCollection:ArrayCollection = chartModelDetails.record.wellnessModel.documents;
			var seriesDataCollection:ArrayCollection = new ArrayCollection();

			for each (var wellness:Wellness in wellnessCollection)
			{
				var proxy:StepsPerDayProxy = new StepsPerDayProxy(wellness);
				proxy.vitalSign = getVitalSignForDay(systolicCollection, wellness.measurementDate);
				seriesDataCollection.addItem(proxy);
			}

			var vitalSignSeries:BubbleSeries;

			vitalSignSeries = new BubbleSeries();
			vitalSignSeries.name = "systolic";
			vitalSignSeries.id = chart.id + "_systolicSeries";
			vitalSignSeries.xField = "measurementDate";
			vitalSignSeries.yField = "systolic";
			vitalSignSeries.radiusField = "radius";
			vitalSignSeries.dataProvider = seriesDataCollection;
			vitalSignSeries.displayName = "Blood Pressure Systolic";
			vitalSignSeries.filterDataValues = "none";
			vitalSignSeries.setStyle("stroke", new SolidColorStroke(0x224488, 2));
			vitalSignSeries.setStyle("fill", new SolidColor(0xFF0000));
			seriesDataSets.push(new SeriesDataSet(vitalSignSeries, seriesDataCollection, "measurementDate"));

			return seriesDataSets;
		}

		private function getVitalSignForDay(vitalSignsCollection:ArrayCollection, measurementDate:Date):VitalSign
		{
			for each (var vitalSign:VitalSign in vitalSignsCollection)
			{
				var dayMeasured:Date = DateUtil.roundTimeToNextDay(measurementDate);
				if (dayMeasured.valueOf() == DateUtil.roundTimeToNextDay(vitalSign.dateMeasuredStart).valueOf())
				{
					return vitalSign;
				}
			}
			return null;
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
