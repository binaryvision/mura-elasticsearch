component extends="testbox.system.BaseSpec" {

    function beforeTests() {
        elasticSearchClient = new MuraElasticSearch.model.ElasticSearchClient("http://localhost:9200");
        elasticSearchClient.setHttpRequestService({request=function() {return arguments}});
    }

    /** SEARCH **************************************************************/

    function test_search_with_index_and_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/testType/_search", body={"query"="test"} },
            elasticSearchClient.search(body={"query"="test"}, index="testIndex", type="testType")
        );
    }

    function test_search_with_index_and_no_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/_search", body={"query"="test"} },
            elasticSearchClient.search(body={"query"="test"}, index="testIndex")
        );
    }

    function test_search_with_no_index_and_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/*/testType/_search", body={"query"="test"} },
            elasticSearchClient.search(body={"query"="test"}, type="testType")
        );
    }

    function test_search_with_no_index_and_no_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/_search", body={"query"="test"} },
            elasticSearchClient.search(body={"query"="test"})
        );
    }

    /** INDICES *************************************************************/

    function test_createIndex() {
        assertExpectedRequestIsMade(
            { method="put", url="http://localhost:9200/testIndex" },
            elasticSearchClient.createIndex("testIndex")
        );
    }

    function test_createIndex_with_no_name()
        expectedException="expression" // missing parameter
    {
        elasticSearchClient.createIndex();
    }

    function test_deleteIndex() {
        assertExpectedRequestIsMade(
            { method="delete", url="http://localhost:9200/testIndex" },
            elasticSearchClient.deleteIndex("testIndex")
        );
    }

    function test_deleteIndex_with_no_name()
        expectedException="expression" // missing parameter
    {
        elasticSearchClient.deleteIndex();
    }

    /** BULK ****************************************************************/

    function test_bulk_with_no_index_and_no_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/_bulk", body='{"index":{"_id":"1","_index":"testIndex","_type":"testType"}}\n{"field1":"value1"}' },
            elasticSearchClient.bulk([
                { "index"={ "_index"="testIndex", "_type"="testType", "_id"="1" } },
                { "field1"="value1" }
            ])
        );
    }

    function test_bulk_with_index_and_no_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/_bulk", body='{"index":{"_id":"1","_type":"testType"}}\n{"field1":"value1"}' },
            elasticSearchClient.bulk(index="testIndex", actions=[
                { "index"={ "_id"="1", "_type"="testType" } },
                { "field1"="value1" }
            ])
        );
    }

    function test_bulk_with_index_and_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/testType/_bulk", body='{"index":{"_id":"1"}}\n{"field1":"value1"}' },
            elasticSearchClient.bulk(index="testIndex", type="testType", actions=[
                { "index"={ "_id"="1" } },
                { "field1"="value1" }
            ])
        );
    }

    /** TEST HELPERS ********************************************************/

    private function assertExpectedRequestIsMade(required expected, required actual) {
        for (var key in expected) {
            $assert.isEqual(expected[key], actual[key]);
        }
    }

}