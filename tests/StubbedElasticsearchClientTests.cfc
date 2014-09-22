component extends="testbox.system.BaseSpec" {

    function beforeTests() {
        elasticsearch = new MuraElasticsearch.model.ElasticsearchClient(
            host="http://localhost:9200",
            httpRequestService={request=function() { structAppend(arguments, { getStatusCode=function(){ return 200; } }, true); return arguments; }}
        );
    }

    /** SEARCH **************************************************************/

    function test_search_with_index_and_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/testType/_search", body={"query"="test"} },
            elasticsearch.search(body={"query"="test"}, index="testIndex", type="testType")
        );
    }

    function test_search_with_index_and_no_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/_search", body={"query"="test"} },
            elasticsearch.search(body={"query"="test"}, index="testIndex")
        );
    }

    function test_search_with_no_index_and_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/*/testType/_search", body={"query"="test"} },
            elasticsearch.search(body={"query"="test"}, type="testType")
        );
    }

    function test_search_with_no_index_and_no_mapping() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/_search", body={"query"="test"} },
            elasticsearch.search(body={"query"="test"})
        );
    }

    /** INDICES *************************************************************/

    function test_createIndex() {
        assertExpectedRequestIsMade(
            { method="put", url="http://localhost:9200/testIndex" },
            elasticsearch.createIndex(name="testIndex")
        );
    }

    function test_createIndex_with_no_name()
        expectedException="expression" // missing parameter
    {
        elasticsearch.createIndex();
    }

    function test_deleteIndex() {
        assertExpectedRequestIsMade(
            { method="delete", url="http://localhost:9200/testIndex" },
            elasticsearch.deleteIndex(name="testIndex")
        );
    }

    function test_deleteIndex_with_no_name()
        expectedException="expression" // missing parameter
    {
        elasticsearch.deleteIndex();
    }

    /** BULK ****************************************************************/

    function test_bulk_with_no_index_and_no_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/_bulk", body='{"index":{"_id":"1","_index":"testIndex","_type":"testType"}}#chr(10)#{"field1":"value1"}#chr(10)#' },
            elasticsearch.bulk(
                actions=[
                    { "index"={ "_index"="testIndex", "_type"="testType", "_id"="1" } },
                    { "field1"="value1" }
                ]
            )
        );
    }

    function test_bulk_with_index_and_no_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/_bulk", body='{"index":{"_id":"1","_type":"testType"}}#chr(10)#{"field1":"value1"}#chr(10)#' },
            elasticsearch.bulk(
                index="testIndex",
                actions=[
                    { "index"={ "_id"="1", "_type"="testType" } },
                    { "field1"="value1" }
                ]
            )
        );
    }

    function test_bulk_with_index_and_type() {
        assertExpectedRequestIsMade(
            { method="post", url="http://localhost:9200/testIndex/testType/_bulk", body='{"index":{"_id":"1"}}#chr(10)#{"field1":"value1"}#chr(10)#' },
            elasticsearch.bulk(
                index="testIndex",
                type="testType",
                actions=[
                    { "index"={ "_id"="1" } },
                    { "field1"="value1" }
                ]
            )
        );
    }

    /** TEST HELPERS ********************************************************/

    private function assertExpectedRequestIsMade(required expected, required actual) {
        for (var key in expected) {
            $assert.isEqual(expected[key], actual[key]);
        }
    }

}