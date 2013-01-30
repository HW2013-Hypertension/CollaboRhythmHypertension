package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSign;
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.VitalSignChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.ChartModifierBase;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;

	import com.dougmccune.controls.AxisRendererExt;

	import com.dougmccune.controls.BlankAxisRenderer;

	import com.dougmccune.controls.LimitedLinearAxis;

	import com.dougmccune.controls.ScrubChart;
	import com.dougmccune.controls.SeriesDataSet;
	import com.theory9.data.types.OrderedMap;
	import com.theory9.data.types.OrderedMap;

	import mx.charts.HitData;
	import mx.charts.LinearAxis;

	import mx.charts.chartClasses.CartesianChart;
	import mx.charts.chartClasses.Series;
	import mx.charts.series.LineSeries;
	import mx.charts.series.PlotSeries;
	import mx.collections.ArrayCollection;
	import mx.controls.Image;
	import mx.core.IVisualElement;
	import mx.graphics.SolidColorStroke;

	import qs.charts.dataShapes.DataDrawingCanvas;
	import qs.charts.dataShapes.Edge;

	import spark.components.Group;

	import spark.components.Label;
	import spark.components.View;

	public class HypertensionChartModifier extends ChartModifierBase implements IChartModifier
	{
		private static const DIASTOLIC_VERTICAL_AXIS_MAXIMUM:Number = 120;
		private static const DIASTOLIC_VERTICAL_AXIS_MINIMUM:Number = 20;

		private static const SYSTOLIC_VERTICAL_AXIS_MAXIMUM:Number = 190;
		private static const SYSTOLIC_VERTICAL_AXIS_MINIMUM:Number = 50;

		[Bindable]
		public var systolicColor:Number = 0x224488;

		[Bindable]
		public var diastolicColor:Number = 0xfdf700;

		[Embed("/assets/images/background.png")]
		private var backgroundImageClass:Class;

		public function HypertensionChartModifier(chartDescriptor:VitalSignChartDescriptor,
												  chartModelDetails:IChartModelDetails,
												  decoratedChartModifier:IChartModifier)
		{
			super(chartDescriptor, chartModelDetails, decoratedChartModifier)
		}

		protected function get vitalSignChartDescriptor():VitalSignChartDescriptor
		{
			return chartDescriptor as VitalSignChartDescriptor;
		}

		private function bloodPressureChart_dataTipFunction(hitData:HitData):String
		{
			var vitalSign:VitalSign = hitData.item as VitalSign;
			if (vitalSign)
			{
				return (hitData.chartItem.element as Series).displayName + "<br/>" +
						"<b>" + vitalSign.result.value + "</b> (" + vitalSign.result.unit.abbrev + ")<br/>" +
						"Date measured: " + vitalSign.dateMeasuredStart.toLocaleString();
			}
			return hitData.displayText;
		}

		public function modifyCartesianChart(chart:ScrubChart,
											 cartesianChart:CartesianChart,
											 isMainChart:Boolean):void
		{
			if (decoratedModifier)
				decoratedModifier.modifyCartesianChart(chart, cartesianChart, isMainChart);
			chart.mainChartTitle = "Blood Pressure (mmHg)";

			var verticalAxis:LinearAxis = cartesianChart.verticalAxis as LinearAxis;
			verticalAxis.minimum = DIASTOLIC_VERTICAL_AXIS_MINIMUM;
			verticalAxis.maximum = DIASTOLIC_VERTICAL_AXIS_MAXIMUM;

			cartesianChart.dataTipFunction = bloodPressureChart_dataTipFunction;

			if (isMainChart)
			{
				var backgroundImage:Image = new Image();
				backgroundImage.id = "backgroundImage";
				backgroundImage.scaleContent = true;
				backgroundImage.maintainAspectRatio = false;
				backgroundImage.alpha = 0.9;
				backgroundImage.source = backgroundImageClass;
				cartesianChart.backgroundElements.push(backgroundImage);
			}
		}

		public function createMainChartSeriesDataSets(chart:ScrubChart,
													  seriesDataSets:Vector.<SeriesDataSet>):Vector.<SeriesDataSet>
		{
			var vitalSignSeries:LineSeries;
			var seriesDataCollection:ArrayCollection;

			vitalSignSeries = new LineSeries();
			vitalSignSeries.name = "systolic";
			vitalSignSeries.id = chart.id + "_systolicSeries";
			vitalSignSeries.xField = "dateMeasuredStart";
			vitalSignSeries.yField = "resultAsNumber";
			seriesDataCollection = chartModelDetails.record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.SYSTOLIC_CATEGORY);
			vitalSignSeries.dataProvider = seriesDataCollection;
			vitalSignSeries.displayName = "Blood Pressure Systolic";
			vitalSignSeries.filterDataValues = "none";
			vitalSignSeries.setStyle("lineStroke", new SolidColorStroke(systolicColor, 4));
			seriesDataSets.push(new SeriesDataSet(vitalSignSeries, seriesDataCollection, "dateMeasuredStart"));

			var axisRenderer:AxisRendererExt = new AxisRendererExt();
			axisRenderer.placement = "left";
			axisRenderer.setStyle("fontSize", 14);
			axisRenderer.setStyle("tickPlacement", "inside");
			axisRenderer.setStyle("labelPlacement", "inside");
			axisRenderer.setStyle("labelAlign", "center");
			axisRenderer.setStyle("showLine", false);
			axisRenderer.setStyle("canClipLabels", false);
			chart.mainChartCover.verticalAxisRenderers.push(axisRenderer);

			var axis:LinearAxis = new LinearAxis();
			axis.minimum = SYSTOLIC_VERTICAL_AXIS_MINIMUM;
			axis.maximum = SYSTOLIC_VERTICAL_AXIS_MAXIMUM;
			vitalSignSeries.verticalAxis = axis;
			axisRenderer.axis = axis;

			vitalSignSeries = new LineSeries();
			vitalSignSeries.name = "diastolic";
			vitalSignSeries.id = chart.id + "_diastolicSeries";
			vitalSignSeries.xField = "dateMeasuredStart";
			vitalSignSeries.yField = "resultAsNumber";
			seriesDataCollection = chartModelDetails.record.vitalSignsModel.getVitalSignsByCategory(VitalSignsModel.DIASTOLIC_CATEGORY);
			vitalSignSeries.dataProvider = seriesDataCollection;
			vitalSignSeries.displayName = "Blood Pressure Diastolic";
			vitalSignSeries.filterDataValues = "none";
			vitalSignSeries.setStyle("lineStroke", new SolidColorStroke(diastolicColor, 4));

			seriesDataSets.push(new SeriesDataSet(vitalSignSeries, seriesDataCollection, "dateMeasuredStart"));

			return seriesDataSets;
		}

		public function createImage(currentChartImage:IVisualElement):IVisualElement
		{
			return decoratedModifier.createImage(currentChartImage);
		}

		public function drawBackgroundElements(canvas:DataDrawingCanvas, zoneLabel:Label):void
		{
		}

		public function updateChartDescriptors(chartDescriptors:OrderedMap):OrderedMap
		{
			return decoratedModifier.updateChartDescriptors(chartDescriptors);
		}
	}
}
