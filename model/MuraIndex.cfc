component accessors=true {
    property name="siteID";
    property name="muraUtils";
    property name="beanFactory";

    function init(required siteID) {
        setSiteID(siteID);
        return this;
    }

    function refresh() {
        cflock scope="elasticsearch_refresh_#getSiteID()#" timeout=5 type="exclusive" {
            var current_index = structGet("application.elasticsearch_indexes.#getSiteID()#");

            if (not structKeyExists(current_index, "finished")) return; // already indexing - raise exception?

            application.elasticsearch_indexes[getSiteID()] = {
                started = now()
            };
        }

        var completed = false;
        var batch_limit = 200;

        try {
            var new_index = createNewIndex();

            var batch = (
                getBeanFactory().getBean("muraFeed")
                    .setSiteID(getSiteID())
                    .setSortBy("lastUpdate")
                    .setSortDirection("asc")
                    .setMaxItems(99999)
                    .setNextN(batch_limit)
                    .getIterator()
            );

            while (batch.getPageIndex() lte batch.pageCount()) {
                var bulk_actions = [];

                while (batch.hasNext()) {
                    var content = batch.next();
                    arrayAppend(bulk_actions, { "index" = { "_id" = content.getContentID() } });
                    arrayAppend(bulk_actions, contentToJSON(content));
                }

                getElasticsearchClient().bulk(bulk_action, new_index, getMuraContentType());

                batch.setPage(batch.getPageIndex() + 1);
            }

            completed = true;

            changeAlias(new_index);
        } finally {
            if (new_index and not completed) deleteIndex(new_index);

            cflock scope="elasticsearch_refresh_#getSiteID()#" timeout=5 type="exclusive" {
                structGet("application.elasticsearch_indexes.#getSiteID()#").finished = now();
            }
        }
    }

    function update(required content) {
        if (not shouldIndex(content)) return remove(content);

        var contentJSON = contentToJSON(content);
        var filenameHasChanged = content.getOldFilename() neq content.getFilename();

        for (var index in getWriteAlias()) {
            getElasticsearchClient().insertDocument(
                index=index,
                type=getMuraContentType(),
                id=content.getContentID(),
                body=contentJSON
            );

            if (filenameHasChanged) updateContentUsingOldFilename(index, content);
        }
    }

    function remove(required content) {
        for (var index in getWriteAlias()) {
            getElasticsearchClient().removeDocument(
                index=getAliasName(),
                type=getMuraContentType(),
                id=content.getContentID()
            );
        }
    }

    function getMuraContentType() {
        return getConfig("ELASTICSEARCH_CONTENT_MAPPING", "muraContent");
    }
    
    function getHost() {
        return getConfig("ELASTICSEARCH_HOST", "http://localhost:9200");
    }

    function getAlias() {
        return structKeyArray(
            getElasticsearchClient().getAlias(
                alias=getAliasName()
            ).toJSON()
        );
    }

    function getAliasName() {
        return getSiteID();
    }

    /** PRIVATE *************************************************************/

    private function createNewIndex() {
        var newIndexName = getAliasName() & "_" & lcase(createUUID());
        getElasticsearchClient().createIndex(newIndexName);
        getElasticsearchClient().createAlias(getWriteAliasName(), newIndexName);
        return newIndexName;
    }

    private function changeAlias(required newIndex) {
        var actions = [];

        // Is there a way to just say remove alias from all indexes?

        for(var index in getAlias())
            arrayAppend({ "remove" = { "index"=index, "alias"=getAliasName() } });

        for(var index in getWriteAlias())
            arrayAppend({ "remove" = { "index"=index, "alias"=getWriteAliasName() } });

        arrayAppend({ "add" = { "index"=newIndex, "alias"=getWriteAliasName() } });
        arrayAppend({ "add" = { "index"=newIndex, "alias"=getAliasName() } });

        return getElasticsearchClient().updateAliases(actions);
    }

    private function getConfig(required key, defaultValue='') {
        return getMuraUtils().getSiteConfig(
            siteid=getSiteID(),
            argumentsCollection=arguments
        );
    }

    private function updateContentUsingOldFilename(required index, required content) {
        var elasticsearch = getElasticsearchClient();

        var scroll_id = elasticsearch.search(
            index=index,
            type=getMuraContentType(),
            body={
                "query"={
                    "prefix"={
                        "filename"=content.getOldFilename()
                    }
                },
                "size"=500
            },
            params={
                "search_type"="scan",
                "scroll"="1m"
            }
        ).toJSON()["_scroll_id"];

        var results = elasticsearch.searchScroll("1m", scroll_id);

        while (arrayLen(results["hits"]["hits"])) {
            var bulk_actions = [];

            for (var i=1; i lt arrayLen(results["hits"]["hits"]); i++) {
                var record = results["hits"]["hits"][i];

                arrayAppend(bulk_actions, { "update"={ "_id"= record["contentID"] } });
                arrayAppend(bulk_actions, {
                    "filename"=replace(record["filename"], content.getOldFilename(), content.getFilename()),
                    "url"=replace(record["url"], content.getOldFilename(), content.getFilename())
                });
            }

            elasticsearch.bulk(
                index=index,
                type=getMuraContentType(),
                actions=bulk_actions
            );

            var results = elasticsearch.searchScroll("1m", scroll_id);
        }
    }

    private function getWriteAlias() {
        return structKeyArray(
            getElasticsearchClient().getAlias(
                alias=getWriteAliasName()
            ).toJSON()
        );
    }

    private function getWriteAliasName() {
        return getAliasName() & getWriteAliasSuffix();
    }

    private function getWriteAliasSuffix() {
        return "_write";
    }

    private function shouldIndex(required content) {
        return getContentIndexer().shouldIndex(content);
    }

    private function contentToJSON(required content) {
        return getContentIndexer().contentToJSON(content);
    }

    private function initContentIndexer() {
        contentIndexer = len(getConfig("ELASTICSEARCH_CONTENT_INDEXER"))
            ? createObject("component", getConfig("ELASTICSEARCH_CONTENT_INDEXER"))
            : getBeanFactory().getBean("ContentIndexer");

        if (isDefined("contentIndex.setBeanFactory"))
            contentIndexer.setBeanFactory(getBeanFactory());
    }

    private function getContentIndexer() {
        if (not isDefined("contentIndexer")) initContentIndexer();

        return contentIndexer;
    }

    private function initElasticsearchClient() {
        elasticsearchClient = getBeanFactory().getBean("ElasticsearchClient").init(host=getHost());
    }

    private function getElasticsearchClient() {
        if (not isdefined("elasticsearchclient")) initElasticsearchClient();

        return elasticsearchClient;
    }

}