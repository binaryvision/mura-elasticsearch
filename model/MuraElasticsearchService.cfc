component accessors=true {
    property name="beanFactory";
    property name="muraService";
    property name="elasticsearchService";

    /** OPERATIONS **********************************************************/

    function refresh(required siteid)
        /* TODO add some locking and better error handling and status reporting (be good to have some trace stuff in for debugging) */
        hint="Refresh a mura sites elasticsearch index, updating the settings, and reloading the content from the database."
    {
        var completed = false;
        var elasticsearch = getElasticsearchClient(siteid);

        try {
            var newIndexName = createNewIndex(siteid);

            var siteContent = (
                getBeanFactory().getBean("feed")
                    .setSiteID(siteid)
                    .setSortBy("lastUpdate")
                    .setSortDirection("asc")
                    .setMaxItems(99999)
                    .setNextN(val(
                        getMuraService().getSiteConfig(
                            siteid=siteid,
                            key="ELASTICSEARCH_BATCH_LIMIT",
                            defaultValue=250
                        )
                    ))
                    .setShowExcludedSearch(true)
                    .setShowNavOnly(false)
                    .getIterator()
            );

            for (var i=1; i lte siteContent.pageCount(); i++) {
                siteContent.setPage(i);

                var actions = [];

                while (siteContent.hasNext()) {
                    var content = siteContent.next();
                    if (shouldIndex(content)) {
                        arrayAppend(actions, { "index" = { "_id" = content.getContentID() } });
                        arrayAppend(actions, contentToJSON(content));
                    }
                }

                elasticsearch.bulk(
                    actions=actions,
                    index=newIndexName,
                    type=getMuraContentType(siteid)
                );
            }

            completed = true;

            changeSiteIndex(siteid, newIndexName);
        } finally {
            if (isDefined("newIndexName") and not completed) {
                elasticsearch.deleteIndex(name=newIndexName);
            }
        }
    }

    function update(required content) {
        if (not shouldIndex(content)) return remove(content);

        var contentJSON = contentToJSON(content);
        var oldFilename = getMuraService().getFilenameOfLastVersion(content);
        var filenameHasChanged = len(oldFilename) and content.getFilename() neq oldFilename;
        var elasticsearch = getElasticsearchClient(content.getSiteID());

        for (var index in getWriteAlias(content.getSiteID())) {
            elasticsearch.insertDocument(
                index=index,
                type=getMuraContentType(content.getSiteID()),
                id=content.getContentID(),
                body=contentJSON
            );

            if (filenameHasChanged) {
                fixFilenames(
                    siteid=content.getSiteID(),
                    index=index,
                    oldFilename=oldFilename,
                    newFilename=content.getFilename()
                );
            }
        }
    }

    function remove(required content) {
        for (var index in getWriteAlias(content.getSiteID())) {
            getElasticsearchClient().removeDocument(
                index=getAliasName(),
                type=getMuraContentType(content.getSiteID()),
                id=content.getContentID()
            );
        }
    }

    /** HELPERS FOR TALKING TO A SITES ELASTICSEARCH INDEX ******************/

    function getElasticsearchClient(required siteid) {
        return getElasticsearchService().getClient(getHost(siteid))
    }

    function getHost(required siteid) {
        return getMuraService().getSiteConfig(
            siteid=siteid,
            key="ELASTICSEARCH_HOST",
            defaultValue="http://localhost:9200"
        );
    }

    function getAlias(required siteid) {
        var response = getElasticsearchClient(siteid).getAlias(name=getAliasName(siteid), throwOnError=false);
        return (
            response.is200()
                ? structKeyArray(response.toJSON())
                : []
        );
    }

    function getAliasName(required siteid) {
        return getMuraService().getSiteConfig(
            siteid=siteid,
            key="ELASTICSEARCH_ALIAS",
            defaultValue=lcase(siteid)
        );
    }

    function getWriteAlias(required siteid) {
        var response = getElasticsearchClient(siteid).getAlias(name=getWriteAliasName(siteid), throwOnError=false);
        return (
            response.is200()
                ? structKeyArray(response.toJSON())
                : []
        );
    }

    function getWriteAliasName(required siteid) {
        return getAliasName(siteid) & getWriteAliasSuffix();
    }

    function getMuraContentType(required siteid) {
        return getMuraService().getSiteConfig(
            siteid=siteid,
            key="ELASTICSEARCH_MURA_CONTENT_TYPE",
            defaultValue="muraContent"
        );
    }

    /** PRIVATE *************************************************************/

    private function getWriteAliasSuffix() {
        return "_write";
    }

    private function createNewIndex(required siteid) {
        var newIndexName = getAliasName(siteid) & "_" & lcase(createUUID());
        var elasticsearch = getElasticsearchClient(siteid);
        elasticsearch.createIndex(name=newIndexName, body=getIndexSettings(siteid));
        elasticsearch.createAlias(name=getWriteAliasName(siteid), index=newIndexName);
        return newIndexName;
    }

    private function changeSiteIndex(required siteid, required newIndexName) {
        var actions = [];

        for(var index in getAlias(siteid))
            arrayAppend(actions, { "remove"={ "index"=index, "alias"=getAliasName(siteid) } });

        for(var index in getWriteAlias(siteid))
            arrayAppend(actions, { "remove"={ "index"=index, "alias"=getWriteAliasName(siteid) } });

        arrayAppend(actions, { "add"={ "index"=newIndexName, "alias"=getWriteAliasName(siteid) } });
        arrayAppend(actions, { "add"={ "index"=newIndexName, "alias"=getAliasName(siteid) } });

        return getElasticsearchClient(siteid).updateAliases(actions=actions);
    }

    private function getIndexSettings(required siteid) {
        getContentIndexer(siteid).getIndexSettings();
    }

    private function shouldIndex(required content) {
        return getContentIndexer(content.getSiteID()).shouldIndex(content);
    }

    private function contentToJSON(required content) {
        return getContentIndexer(content.getSiteID()).contentToJSON(content);
    }

    function getContentIndexer(required siteid) {
        if (not structKeyExists(structGet("variables.indexers"), siteid)) {
            var contentIndexer = getMuraService().getSiteConfig(
                siteid=siteid,
                key="ELASTICSEARCH_CONTENT_INDEXER"
            );

            variables.indexers[siteid] = (
                len(contentIndexer)
                    ? createObject("component", contentIndexer).setBeanFactory(getBeanFactory())
                    : getBeanFactory().getBean("ContentIndexer")
            );
        }

        return variables.indexers[siteid];
    }

    function fixFilenames(
        required siteid,
        required index,
        required oldFilename,
        required newFilename
    ) {
        getElasticsearchClient(siteid).searchAndReplace(
            index=index, 
            type=getMuraContentType(siteid),
            body={
                "query"={
                    "match"={ // note that this requries a custom analyzer using path_hierarchy_tokenizer to work! see indexSettings.json
                        "filename"=oldFilename
                    }
                }
            },
            fields="url,filename",
            oldValue=oldFilename,
            newValue=newFilename
        );
    }

}