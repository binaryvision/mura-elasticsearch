component persistent="false" output="false" extends="mura.plugin.pluginGenericEventHandler" {

    public void function onApplicationLoad(required struct $) {
        variables.pluginConfig.addEventHandler(this);
        getServiceFactory().addBean("MuraElasticSearch", new MuraElasticSearch.MuraElasticSearch());
    }

}