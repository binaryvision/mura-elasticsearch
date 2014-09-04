component accessors=true {
    property name="muraService";
    property name="elasticsearchService";

    function getElasticsearchClient(siteid) {
        return getElasticsearchService().getClient(getHost(siteid))
    }

    function getHost(siteid) {
        return getMuraService().getSiteConfig(
            siteid=siteid,
            key="ELASTICSEARCH_HOST",
            defaultValue="http://localhost:9200"
        );
    }

}