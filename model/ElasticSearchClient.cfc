component accessors=true {
    property name="Host";
    property name="HttpRequestService";
    property name="ElasticsearchService";

    function search(
        required body,
        index="",
        type="",
        params="",
        throwOnError=true        
    ) {
        if (not len(index) and len(type)) index = "*";

        if (isStruct(params)) params = structToQueryString(params);

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_search") & params,
            body=body,
            throwOnError=throwOnError
        );
    }

    function searchScroll(
        required scroll,
        required scrollID,
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="get",
            url=createURL("_search", "scroll") & structToQueryString({scroll=scroll, scroll_id=scrollID}),
            throwOnError=throwOnError
        );
    }

    /*** INDEX METHODS ******************************************************/

    function createIndex(
        required name,
        body="",
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(name),
            body=body,
            throwOnError=throwOnError
        );
    }

    function deleteIndex(
        required name,
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(name),
            throwOnError=throwOnError
        );
    }

    function indexExists(
        required name,
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(name),
            throwOnError=throwOnError
        ).is200();
    }

    function refreshIndex(
        name="",
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(name, "_refresh"),
            throwOnError=throwOnError
        );
    }

    /*** ALIAS METHODS ******************************************************/

    function createAlias(
        required name,
        required index,
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"add"= {"index"=index, "alias"=name}}
                ]
            },
            throwOnError=throwOnError
        );
    }

    function removeAlias(
        required name,
        index="_all",
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"remove"= {"index"=index, "alias"=name}}
                ]
            },
            throwOnError=throwOnError
        );
    }

    function changeAlias(
        required name,
        required index,
        previousIndex="_all",
        throwOnError=true        
    ) {
        return updateAliases(
            [
                {"remove" = {"index"=previousIndex, "alias"=name}},
                {"add" = {"index"=index, "alias"=name}}
            ],
            throwOnError=throwOnError
        );
    }

    function updateAliases(
        required actions,
        throwOnError=true        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=actions
            },
            throwOnError=throwOnError
        );
    }

    function getAlias(
        index="",
        alias="",
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="get",
            url=createUrl(index, "_alias", alias),
            throwOnError=throwOnError
        );
    }

    function aliasExists(
        required name,
        index="",
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, "_alias", name),
            throwOnError=throwOnError
        ).is200();
    }

    /*** DOCUMENT METHODS ***************************************************/

    function insertDocument(
        required index,
        required type,
        required id,
        required body,
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(index, type, id),
            body=body,
            throwOnError=throwOnError
        );
    }

    function updateDocument(
        required index,
        required type,
        required id,
        required body,
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, id, "_update"),
            body=body,
            throwOnError=throwOnError
        );
    }

    function documentExists(
        required index,
        required type,
        required id,
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, type, id),
            throwOnError=throwOnError
        ).is200();
    }

    function removeDocument(
        required index,
        required type,
        required id,
        throwOnError=true
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(index, type, id),
            throwOnError=throwOnError
        );
    }

    /*** BULK ***************************************************************/

    function bulk(
        required actions,
        index="",
        type="",
        throwOnError=true
    ) {
        for (var i=1; i lte arrayLen(actions); i++) {
            if (not isJSON(actions[i])) actions[i] = serializeJSON(actions[i]);
        }

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_bulk"),
            body=arrayToList(actions, "#chr(10)#") & "#chr(10)#",
            throwOnError=throwOnError
        );
    }
 
    /*** PRIVATE METHODS ****************************************************/

    private function getHost() {
        return variables.host;
    }

    private function createUrl() {
        var href = getHost();

        for(var param in arguments) {
            if(len(arguments[param])) { href = listAppend(href, arguments[param], "/"); }
        }

        return href;
    }

    private function makeHttpRequest() {
        var throwOnError = arguments.throwOnError;

        arguments.throwOnError = false;

        var response = getHttpRequestService().request(argumentCollection=arguments);

        if (throwOnError and not response.is200()) {
            throw(
                type="Elasticsearch",
                message=structKeyExists(response.toJSON(), "error") ? response.toJSON().error : "Elasticsearch error",
                detail=response.toString(),
                errorCode=response.toJSON().status
            );
        }

        return response;
    }

    private function structToQueryString(required structure) {
        var queryString = "";
        for (var key in structure) {
            queryString = listAppend(queryString, URLEncodedFormat(lcase(key)) & "=" & URLEncodedFormat(structure[key]), "&");
        }
        return "?" & queryString;
    }

}