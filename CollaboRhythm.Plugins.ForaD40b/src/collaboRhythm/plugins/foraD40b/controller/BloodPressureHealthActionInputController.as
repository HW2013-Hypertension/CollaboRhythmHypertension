package collaboRhythm.plugins.foraD40b.controller
{
	import collaboRhythm.plugins.foraD40b.model.BloodPressureHealthActionInputModel;
	import collaboRhythm.plugins.foraD40b.model.ForaD40bHealthActionInputControllerFactory;
	import collaboRhythm.plugins.foraD40b.view.BloodPressureHealthActionInputView;
	import collaboRhythm.plugins.schedule.shared.controller.HealthActionInputControllerBase;
	import collaboRhythm.plugins.schedule.shared.model.HealthActionInputModelAndController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.shared.model.BackgroundProcessCollectionModel;
	import collaboRhythm.shared.model.DateUtil;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import flash.events.MouseEvent;
	import flash.net.URLVariables;

	import spark.components.ViewNavigator;
	import spark.transitions.SlideViewTransition;

	public class BloodPressureHealthActionInputController extends HealthActionInputControllerBase implements IHealthActionInputController
	{
		private const HEALTH_ACTION_INPUT_VIEW_CLASS:Class = BloodPressureHealthActionInputView;

		private var _dataInputModel:BloodPressureHealthActionInputModel;
		private var _viewNavigator:ViewNavigator;
		private var _backgroundProcessModel:BackgroundProcessCollectionModel;

		public function BloodPressureHealthActionInputController(scheduleItemOccurrence:ScheduleItemOccurrence,
														 healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
														 viewNavigator:ViewNavigator)
		{
			_dataInputModel = new BloodPressureHealthActionInputModel(scheduleItemOccurrence, healthActionModelDetailsProvider);
			_viewNavigator = viewNavigator;
			_backgroundProcessModel = BackgroundProcessCollectionModel(WorkstationKernel.instance.resolve(BackgroundProcessCollectionModel));
		}

		public function handleHealthActionResult(initiatedLocally:Boolean):void
		{
			var healthActionInputModelAndController:HealthActionInputModelAndController = new HealthActionInputModelAndController(_dataInputModel,
					this);

			_viewNavigator.pushView(HEALTH_ACTION_INPUT_VIEW_CLASS, healthActionInputModelAndController, null,
					new SlideViewTransition());
		}

		public function handleHealthActionSelected():void
		{
		}

		public function handleUrlVariables(urlVariables:URLVariables):void
		{
			var batchTransferAction:String = urlVariables[BATCH_TRANSFER_URL_VARIABLE];
			if (batchTransferAction == HealthActionInputControllerBase.BATCH_TRANSFER_ACTION_BEGIN)
			{
//				backgroundProcessModel.updateProcess(BATCH_TRANSFER_PROCESS_KEY, "Transferring data from " + ForaD40bHealthActionInputControllerFactory.EQUIPMENT_NAME + "...", true);
			}
			else if (batchTransferAction == HealthActionInputControllerBase.BATCH_TRANSFER_ACTION_END)
			{
//				backgroundProcessModel.updateProcess(BATCH_TRANSFER_PROCESS_KEY, null, false);
			}
			else
			{
				handleUrlVariablesNewMeasurement(urlVariables);
			}
		}

		private function handleUrlVariablesNewMeasurement(urlVariables:URLVariables):void
		{
/*
			if (!isValidMeasurement(urlVariables))
			{
				_logger.debug("handleUrlVariablesNewMeasurement invalid urlVariables " + urlVariables.toString());
				return;
			}
*/

/*
				// only handle additional measurements if they are before the currently queued measurement(s)
				var previousDataInputModel:BloodGlucoseHealthActionInputModel = (_dataInputModelCollection.reportBloodGlucoseItemDataCollection[_dataInputModelCollection.reportBloodGlucoseItemDataCollection.length -
						1] as ReportBloodGlucoseItemData).dataInputModel;
				if (_stopIfOutOfOrder && DateUtil.parseW3CDTF(urlVariables.correctedMeasuredDate).valueOf() >=
						previousDataInputModel.dateMeasuredStart.valueOf())
				{
					_logger.warn("handleUrlVariables ignored because incoming correctedMeasuredDate " +
							urlVariables.correctedMeasuredDate + " was not before currently queued measurement " +
							DateUtil.format(previousDataInputModel.dateMeasuredStart) + ". urlVariables: " +
							urlVariables.toString());
					return;
				}

				itemData = new ReportBloodGlucoseItemData(new BloodGlucoseHealthActionInputModel(null,
						_dataInputModelCollection.healthActionModelDetailsProvider,
						_dataInputModelCollection.scheduleCollectionsProvider,
						_dataInputModelCollection), this);
				_dataInputModelCollection.reportBloodGlucoseItemDataCollection.addItem(itemData);
*/

/*
			itemData.dataInputModel.isDuplicate = _duplicateDetected;
			itemData.dataInputModel.handleUrlVariables(urlVariables);
*/

//			var guessedScheduleItemOccurrence:ScheduleItemOccurrence = _dataInputModel.guessScheduleItemOccurrence();

			if (!_dataInputModel.isFromDevice)
			{
				_dataInputModel.urlVariables = urlVariables;
				handleAdherenceChange(_dataInputModel, _dataInputModel.scheduleItemOccurrence, true);
				safeSendBroadcastDuplicateDetected();

				var healthActionInputModelAndController:HealthActionInputModelAndController = new HealthActionInputModelAndController(_dataInputModel,
						this);

				_viewNavigator.pushView(HEALTH_ACTION_INPUT_VIEW_CLASS, healthActionInputModelAndController, null,
						new SlideViewTransition());
			}
		}

		override public function shouldIgnoreUrlVariables(urlVariables:URLVariables):Boolean
		{
			return urlVariables;
		}

		public function submitBloodPressure(position:String, site:String):void
		{
			_dataInputModel.submitBloodPressure(position, site);
			_viewNavigator.popView();
		}

		public function get healthActionInputViewClass():Class
		{
			return HEALTH_ACTION_INPUT_VIEW_CLASS;
		}

		public function useDefaultHandleHealthActionResult():Boolean
		{
			return false;
		}

		public function updateDateMeasuredStart(date:Date):void
		{
		}

		public function handleHealthActionCommandButtonClick(event:MouseEvent):void
		{
		}

		public function removeEventListener():void
		{
		}

		public function get backgroundProcessModel():BackgroundProcessCollectionModel
		{
			return _backgroundProcessModel;
		}
	}
}
