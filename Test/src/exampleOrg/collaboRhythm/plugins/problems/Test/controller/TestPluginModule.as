package exampleOrg.collaboRhythm.plugins.problems.Test.controller
{
	import castle.flexbridge.reflection.ReflectionUtils;

	import collaboRhythm.plugins.schedule.shared.model.IHealthActionCreationControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionInputControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionListViewAdapterFactory;
	import collaboRhythm.shared.controller.apps.AppControllerInfo;
	import collaboRhythm.shared.model.services.IComponentContainer;
	import collaboRhythm.shared.pluginsSupport.IPlugin;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifierFactory;

	import mx.modules.ModuleBase;

	public class TestPluginModule extends ModuleBase implements IPlugin
	{
		public function TestPluginModule()
		{
			super();
		}

		public function registerComponents(componentContainer:IComponentContainer):void
		{
			// TODO: each plugin should register one or more of the following components; implement or delete the code below as appropriate; using the CollaboRhythm file templates in IntelliJ IDEA may make this easier
			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(TestAppController).name,
					AppControllerInfo,
					new AppControllerInfo(TestAppController));

			/* componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(TestHealthActionListViewAdapterFactory).name,
					IHealthActionListViewAdapterFactory,
					new TestHealthActionListViewAdapterFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(TestHealthActionInputControllerFactory).name,
					IHealthActionInputControllerFactory,
					new TestHealthActionInputControllerFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(TestChartModifierFactory).name,
					IChartModifierFactory,
					new TestChartModifierFactory());

			componentContainer.registerComponentInstance(ReflectionUtils.getClassInfo(TestHealthActionCreationControllerFactory).name,
					IHealthActionCreationControllerFactory,
					new TestHealthActionCreationControllerFactory()); */
		}
	}
}
