component accessors=true {
    property name="configBean";
    property name="pluginManager";
    property name="settingsManager";

    function getSite(required siteid) {
        return getSettingsManager().getSite(siteid);
    }

    function getSiteConfig(required siteID, required key, defaultValue='') {
        return len(getSite(siteID).getValue(key))
            ? getSite(siteID).getValue(key)
            : defaultValue;
    }

    function getInstanceConfig(required key, defaultValue='') {
        return len(getConfigBean().getValue(key))
            ? getConfigBean().getValue(key)
            : defaultValue;
    }

    function announceEvent(required eventName, eventObject={}, firstOnly=false) {
        return getPluginManager().announceEvent(
            eventToAnnounce=name,
            currentEvetnObject=(isObject(event) ? event : createEvent(event)),
            index=(firstOnly ? 1 : 0) // only fire first handler found
        );
    }

}