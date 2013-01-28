package hw2013Hypertension.plugins.problems.hypertension.model
{
	import collaboRhythm.plugins.schedule.shared.model.EquipmentHealthAction;
	import collaboRhythm.plugins.schedule.shared.model.HealthActionBase;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputController;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.plugins.schedule.shared.model.IScheduleCollectionsProvider;
	import collaboRhythm.plugins.schedule.shared.model.MedicationHealthAction;
	import collaboRhythm.shared.model.ICollaborationLobbyNetConnectionServiceProxy;
	import collaboRhythm.shared.model.healthRecord.document.ScheduleItemOccurrence;
	import hw2013Hypertension.plugins.problems.hypertension.controller.AdhereTechBottleHealthActionInputController;

	import flash.net.URLVariables;

	import spark.components.ViewNavigator;

	public class AdhereTechBottleHealthActionInputControllerFactory implements IHealthActionInputControllerFactory
	{
		private static const EQUIPMENT_NAME:String = "AdhereTechBottle";

		public function AdhereTechBottleHealthActionInputControllerFactory()
		{
		}

		public function createHealthActionInputController(healthAction:HealthActionBase,
														  scheduleItemOccurrence:ScheduleItemOccurrence,
														  healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
														  scheduleCollectionsProvider:IScheduleCollectionsProvider,
														  viewNavigator:ViewNavigator,
														  currentHealthActionInputController:IHealthActionInputController,
														  collaborationLobbyNetConnectionServiceProxy:ICollaborationLobbyNetConnectionServiceProxy):IHealthActionInputController
		{
			if (healthAction.type == MedicationHealthAction.TYPE)
			{
				var medicationHealthAction:MedicationHealthAction = healthAction as MedicationHealthAction;
				if (medicationHealthAction)
				{
					return new AdhereTechBottleHealthActionInputController(scheduleItemOccurrence,
							healthActionModelDetailsProvider, viewNavigator);
				}
			}
			return currentHealthActionInputController;
		}

		public function createDeviceHealthActionInputController(urlVariables:URLVariables,
																healthActionModelDetailsProvider:IHealthActionModelDetailsProvider,
																scheduleCollectionsProvider:IScheduleCollectionsProvider,
																viewNavigator:ViewNavigator,
																currentDeviceHealthActionInputController:IHealthActionInputController):IHealthActionInputController
		{
			var scheduleItemOccurrence:ScheduleItemOccurrence;
			if (urlVariables.healthActionType == EquipmentHealthAction.TYPE &&
					urlVariables.equipmentName == EQUIPMENT_NAME)
			{
				scheduleItemOccurrence = scheduleCollectionsProvider.findClosestScheduleItemOccurrence(EQUIPMENT_NAME,
						urlVariables.dateMeasuredStart);
				return new AdhereTechBottleHealthActionInputController(scheduleItemOccurrence,
						healthActionModelDetailsProvider, viewNavigator);
			}
			else
			{
				return currentDeviceHealthActionInputController;
			}
		}
	}
}
