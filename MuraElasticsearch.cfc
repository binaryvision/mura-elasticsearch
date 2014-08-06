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

    /** ACTIONS *************************************************************/

    function refreshSiteIndex(required siteid) {
        return getMuraIndex(siteid).refresh();
    }

    function updateContent(required content) {
        return getMuraIndex(content.getSiteID()).update(content);
    }

    function removeContent(required content) {
        return getMuraIndex(content.getSiteID()).remove(content);
    }

    /** PRIVATE *************************************************************/

    private function getMuraIndex(required siteid) {
        return getBean("MuraIndex").setSiteID(siteid); // maybe cache these?
    }

}