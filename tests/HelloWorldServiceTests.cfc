/*
   /plugins/MuraElasticsearch/tests/HelloWorldServiceTest.cfc?method=runRemote
   /testbox/test-browser/index.cfm?path=/../../../plugins/MuraElasticsearch/tests
   /testbox/test-runner/?target=muraelasticsearch.tests
*/
component extends="testbox.system.BaseSpec" {

    function beforeTests() {
        MuraElasticSearch = new MuraElasticsearch.MuraElasticSearch();
        HelloWorldService = MuraElasticsearch.getBean("HelloWorldService");
        // -or-
        // HelloWorldService = new MuraElasticsearch.model.HelloWorldService();
    }

    function test_greet_returns_hello_world() {
        $assert.isEqual("Hello world!", HelloWorldService.greet());
    }

}