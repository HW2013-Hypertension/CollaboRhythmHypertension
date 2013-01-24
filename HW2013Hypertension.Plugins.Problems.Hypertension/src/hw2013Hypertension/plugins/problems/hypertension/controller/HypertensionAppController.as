package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import collaboRhythm.shared.collaboration.model.CollaborationLobbyNetConnectionServiceProxy;
	import collaboRhythm.shared.collaboration.model.SynchronizationService;
	import collaboRhythm.shared.controller.apps.AppControllerBase;
	import collaboRhythm.shared.controller.apps.AppControllerConstructorParams;

	import hw2013Hypertension.plugins.problems.hypertension.model.HypertensionModel;

	import hw2013Hypertension.plugins.problems.hypertension.view.HypertensionButtonWidgetView;
	import hw2013Hypertension.plugins.problems.hypertension.view.HypertensionView;

	import mx.core.UIComponent;

	public class HypertensionAppController extends AppControllerBase
	{
		public static const DEFAULT_NAME:String = "Hypertension";

		private var _widgetView:HypertensionButtonWidgetView;

		private var _model:HypertensionModel;
		private var _collaborationLobbyNetConnectionServiceProxyLocal:CollaborationLobbyNetConnectionServiceProxy;
		private var _synchronizationService:SynchronizationService;

		public function HypertensionAppController(constructorParams:AppControllerConstructorParams)
		{
			super(constructorParams);

			_collaborationLobbyNetConnectionServiceProxyLocal = _collaborationLobbyNetConnectionServiceProxy as
					CollaborationLobbyNetConnectionServiceProxy;
			_synchronizationService = new SynchronizationService(this,
					_collaborationLobbyNetConnectionServiceProxyLocal);
		}

		override public function initialize():void
		{
			super.initialize();
			initializeHypertensionModel();

			updateWidgetViewModel();
		}

		private function initializeHypertensionModel():void
		{
			if (_model == null)
			{
				_model = new HypertensionModel(_activeRecordAccount);
			}
		}

		override protected function createWidgetView():UIComponent
		{
			initializeHypertensionModel();

			_widgetView = new HypertensionButtonWidgetView();
			return _widgetView;
		}

		override public function reloadUserData():void
		{
			removeUserData();

			super.reloadUserData();
		}

		override protected function updateWidgetViewModel():void
		{
			super.updateWidgetViewModel();

			if (_widgetView && _activeRecordAccount)
			{
				_widgetView.init(this, _model);
			}
		}

		public override function get defaultName():String
		{
			return DEFAULT_NAME;
		}

		override public function get widgetView():UIComponent
		{
			return _widgetView;
		}

		override public function set widgetView(value:UIComponent):void
		{
			_widgetView = value as HypertensionButtonWidgetView;
		}

		override public function get isFullViewSupported():Boolean
		{
			return false;
		}

		override protected function get shouldShowFullViewOnWidgetClick():Boolean
		{
			return false;
		}

		protected override function removeUserData():void
		{
			_model = null;
			// unregister any components in the _componentContainer here, such as:
			// _componentContainer.unregisterServiceType(IIndividualMessageHealthRecordService);
		}

		public function showHypertensionView():void
		{
			if (_synchronizationService.synchronize("showHypertensionView"))
			{
				return;
			}

			_viewNavigator.pushView(HypertensionView, _model);
		}

		override public function close():void
		{
			if (_synchronizationService)
			{
				_synchronizationService.removeEventListener(this);
				_synchronizationService = null;
			}

			super.close();
		}

		public function get model():HypertensionModel
		{
			return _model;
		}
	}
}
