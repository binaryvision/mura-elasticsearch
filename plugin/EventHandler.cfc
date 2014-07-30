component persistent="false" output="false" extends="mura.plugin.pluginGenericEventHandler" {

    public void function onApplicationLoad(required struct $) {
        variables.pluginConfig.addEventHandler(this);
        getServiceFactory().addBean(
            "MuraElasticsearch",
            new MuraElasticsearch.MuraElasticsearch().setParentBeanFactory(getServiceFactory())
        );
    }

    public void function onContentSave(required struct $) {
        getBean("MuraElasticsearch").updateContent($.getContentBean());
    }

    public void function onContentDelete(required struct $) {
        getBean("MuraElasticsearch").removeContent($.getContentBean());
    }

}