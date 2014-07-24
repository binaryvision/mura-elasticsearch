component accessors=true {
    property name="serviceFactory";
    property name="parentServiceFactory";

    function init(parentServiceFactory) {
        if (isDefined("arguments.parentServiceFactory"))
            setParentServiceFactory(parentServiceFactory);
    }

    function getServiceFactory() {
        if (not isDefined("serviceFactory")) initServiceFactory();

        return serviceFactory;
    }

    function initServiceFactory() {
        serviceFactory = new vendor.ioc("/MuraElasticsearch/model", { singletonPattern = "(Service|Factory)$" });
        
        if (isDefined("variables.parentServiceFactory"))
            serviceFactory.setParent(getParentServiceFactory());
    }

    function getBean(required name) {
        return getServiceFactory().getBean(name);
    }

}