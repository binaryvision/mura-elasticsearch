component extends="testbox.system.BaseSpec" {

    function beforeTests() {
        pluginService = new MuraElasticsearch.MuraElasticSearch();
        elasticsearch = pluginService.getBean("ElasticsearchClient").setHost("http://localhost:9200");
    }

    function setUp() {
        indices = []
        for(var i=1;i<2;i++) { indices[i] = "test_index_" & lcase(createUUID()); }
    }

    function removeTestIndices() {
        for(var index in indices) {
            elasticsearch.deleteIndex(name=index, ignore="404");
        }
    }

    function test_createIndex_and_indexExists_and_deleteIndex() {
        try {

            elasticsearch.createIndex(name=indices[1]);
            $assert.isTrue(elasticsearch.indexExists(name=indices[1]));
            elasticsearch.deleteIndex(name=indices[1]);
            $assert.isFalse(elasticsearch.indexExists(name=indices[1]));

        } finally { removeTestIndices(); }
    }

    function test_insertDocument_and_documentExists_and_removeDocument() {
        try {

            elasticsearch.createIndex(name=indices[1]);

            elasticsearch.insertDocument(
                index=indices[1],
                type="test",
                id=1,
                body={}
            );

            $assert.isTrue(elasticsearch.documentExists(
                index=indices[1],
                type="test",
                id=1
            ));

            elasticsearch.removeDocument(
                index=indices[1],
                type="test",
                id=1
            );

            $assert.isFalse(elasticsearch.documentExists(
                index=indices[1],
                type="test",
                id=1
            ));

        } finally { removeTestIndices(); }
    }

}