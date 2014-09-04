component accessors=true {
    property name="beanFactory";
    property name="parentBeanFactory";

    function init(parentBeanFactory) {
        if (isDefined("arguments.parentBeanFactory"))
            setParentBeanFactory(parentBeanFactory);
    }

    function getBeanFactory() {
        if (not isDefined("beanFactory")) initBeanFactory();

        return beanFactory;
    }

    function initBeanfactory() {
        beanFactory = new vendor.ioc("/MuraElasticsearch/model", { singletonPattern = "(Service|Factory|Manager)$" });
        
        if (isDefined("variables.parentBeanFactory"))
            beanFactory.setParent(getParentBeanFactory());
    }

    function getBean(required name) {
        return getBeanFactory().getBean(name);
    }

    /** ACTIONS / ENTRYPOINTS ***********************************************/

    function refreshSiteIndex(required siteid) {
        return getBean("MuraElasticsearchService").refresh(siteid);
    }

    function updateContent(required content) {
        return getBean("MuraElasticsearchService").update(content);
    }

    function removeContent(required content) {
        return getBean("MuraElasticsearchService").remove(content);
    }

}