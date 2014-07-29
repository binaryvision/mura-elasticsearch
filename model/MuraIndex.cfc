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
            var batch = // find_content limit=batch_limit order_by=last_updated

            while (batch.recordCount > 0) {
                var bulk_actions = [];

                for (var i; i lt batch.recordCount; i++) {
                    arrayAppend(bulk_actions, { "index" = { "_id" = "" } });
                    arrayAppend(bulk_actions, {});
                }

                getElasticsearchClient().bulk(bulk_action, new_index, getMuraContentType());

                var batch = // find_content limit=batch_limit order_by=last_updated where last_updated >= last_processed // reprocess just in case we have some with same last_updated and they happen to span a batch gap
            }

            completed = true;

            changeAlias(new_index);
        } finally {
            if (new_index and not completed) deleteIndex(new_index);

            cflock scope="elasticsearch_refresh_#getSiteID()#" timeout=5 type="exclusive" {
                structGet("application.elasticsearch_indexes.#getSiteID()#").finished = now();
            }
        }

        /*
            cflock refreshing siteid timeout=5 {
                if (refreshing[siteid])
                    return
                else
                    application.refreshing[siteid] = true // maybe have it as a struct with { started , finished }
            }

            completed = false

            batch_limit = 200

            try {
                new_index = create_new_site_index // create and add to write_alias

                batch = find_content limit=batch_limit order_by=last_updated

                while batch.count > 0

                    bulk_actions = []

                    for content in batch

                        bulk_actions << { index = { id = content.id } }
                        bulk_actions << serialize(content)

                        last_processed = content.last_updated

                    client.bulk new_index type bulk_actions

                    batch = find_content limit=batch_limit order_by=last_updated where last_updated >= last_processed // reprocess just in case we have some with same last_updated and they happen to span a batch gap

                completed = true

                change_site_alias new_index
            finally {
                if new_index
                    unless completed delete_index new_index

                application.refreshing[siteid] = false
            }
        */
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
            )

            if (filenameHasChanged) updateContentUsingOldFilename(index, content);
        }
    }

    function remove(required content) {
        for (var index in getWriteAlias()) {
            getElasticsearchClient().removeDocument(
                index=getAlias(),
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
        return getSiteID();
    }

    /** PRIVATE *************************************************************/

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
        return getAlias() & getWriteAliasSuffix();
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