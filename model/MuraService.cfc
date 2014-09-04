component accessors=true {
    property name="configBean";
    property name="pluginManager";
    property name="settingsManager";
    property name="beanFactory";

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

    function getPathToAssociatedFile(required content) {
        var delim = getConfigBean().getFileDelim();
        return (len(content.getFileID())
            ? getConfigBean().getFileDir() & delim & content.getSiteID() & delim & "cache" & delim & "file" & delim & content.getFileID() & "." & content.getFileExt()
            : "");
    }

    function getFilenameOfLastVersion(required content) {
        var dbtype = lcase(getConfigBean().getDBType());

        // wish there was an easy way to do limit 1 offset 1 across sql versions
        var q = new query(datasource=getConfigBean().getDatasource(), sql="
            select #dbtype eq "mssql" ? "top 2" : ""#
                tcontent.filename
            from tcontent 
            where
                tcontent.contentid = :contentID
                and tcontent.siteid = :siteID
                and tcontent.active = 0
            order by tcontent.lastupdate desc
            #dbtype eq "mysql" ? "limit 2" : ""#
        ");

        q.addParam(name="contentID", value=content.getContentID(), cfsqltype="cf_sql_varchar");
        q.addParam(name="siteID", value=content.getSiteID(), cfsqltype="cf_sql_varchar");

        var result = q.execute().getResult();

        return result.recordCount gt 1 ? result.filename[2] : '';
    }

}