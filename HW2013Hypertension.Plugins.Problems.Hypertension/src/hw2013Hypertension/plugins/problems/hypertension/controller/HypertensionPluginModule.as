package hw2013Hypertension.plugins.problems.hypertension.controller
{
	import castle.flexbridge.reflection.ReflectionUtils;

	import collaboRhythm.plugins.schedule.shared.model.IHealthActionCreationControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionListViewAdapterFactory;
	import collaboRhythm.shared.controller.apps.AppControllerInfo;
	import collaboRhythm.shared.model.services.IComponentContainer;
	import collaboRhythm.shared.pluginsSupport.IPlugin;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifierFactory;

	import hw2013Hypertension.plugins.problems.hypertension.model.AdhereTechBottleHealthActionInputControllerFactory;

	import hw2013Hypertension.plugins.problems.hypertension.controller.HypertensionChartsAppController;

	import mx.modules.ModuleBase;

	public class HypertensionPluginModule extends ModuleBase implements IPlugin
	{
		public function HypertensionPluginModule()
		{
			super();
		}

		public function registerComponents(componentContainer:IComponentContainer):void
		{
			// TODO: each plugin should register one or more of the following components; implement or delete the code below as appropriate; using the CollaboRhythm file templates in IntelliJ IDEA may make this easier
			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionAppController).name,
					AppControllerInfo,
					new AppControllerInfo(HypertensionAppController));

						// TODO: each plugin should register one or more of the following components; implement or delete the code below as appropriate; using the CollaboRhythm file templates in IntelliJ IDEA may make this easier
			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionChartsAppController).name,
					AppControllerInfo,
					new AppControllerInfo(HypertensionChartsAppController));

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(AdhereTechBottleHealthActionInputControllerFactory).name,
					IHealthActionInputControllerFactory,
					new AdhereTechBottleHealthActionInputControllerFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionChartModifierFactory).name,
					IChartModifierFactory,
					new HypertensionChartModifierFactory());

/*			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionHealthActionListViewAdapterFactory).name,
					IHealthActionListViewAdapterFactory,
					new HypertensionHealthActionListViewAdapterFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionHealthActionInputControllerFactory).name,
					IHealthActionInputControllerFactory,
					new HypertensionHealthActionInputControllerFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(HypertensionHealthActionCreationControllerFactory).name,
					IHealthActionCreationControllerFactory,
					new HypertensionHealthActionCreationControllerFactory());*/
		}
	}
}
