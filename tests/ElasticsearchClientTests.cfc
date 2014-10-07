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

    function test_searchAndReplace() {
        try {

            elasticsearch.createIndex(name=indices[1]);

            elasticsearch.insertDocument(
                index=indices[1],
                type="test",
                id=1,
                body={ "path1"="a/b/c/d/e" }
            );

            elasticsearch.insertDocument(
                index=indices[1],
                type="test",
                id=2,
                body={ "path1"="a/b/c/d/e", "path2"="a/b/c/d/e", "path3"="a/b/c/d/e" }
            );

            elasticsearch.refreshIndex(indices[1]);

            elasticsearch.searchAndReplace(
                index=indices[1],
                type="test",
                body={
                    "query"={
                        "match_all"={}
                    }
                },
                fields="path1,path2",
                regex="c/d",
                substring="x/y",
                scope="all"
            );

            var doc1 = elasticsearch.getDocument(indices[1], "test", 1).toJSON();
            var doc2 = elasticsearch.getDocument(indices[1], "test", 2).toJSON();

            $assert.isEqual(
                "a/b/x/y/e",
                doc1["_source"]["path1"]
            );

            $assert.isEqual(
                "a/b/x/y/e",
                doc2["_source"]["path1"]
            );

            $assert.isEqual(
                "a/b/x/y/e",
                doc2["_source"]["path2"]
            );

            $assert.isEqual(
                "a/b/c/d/e",
                doc2["_source"]["path3"]
            );


        } finally { removeTestIndices(); }
    }

}