component accessors=true {
    property name="Host";
    property name="HttpRequestService";

    function init(
        host,
        httpRequestService
    ) {
        setHost(arguments.host);
        setHttpRequestService(arguments.httpRequestService);
        return this;
    }

    function search(
        required body,
        index="",
        type="",
        params="",
        ignore=""        
    ) {
        if (not len(index) and len(type)) index = "*";

        if (isStruct(params)) params = structToQueryString(params);

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_search") & params,
            body=body,
            ignore=ignore
        );
    }

    function searchScroll(
        required scroll,
        required scrollID,
        ignore=""        
    ) {
        return makeHttpRequest(
            method="get",
            url=createURL("_search", "scroll") & structToQueryString({scroll=scroll, scroll_id=scrollID}),
            ignore=ignore
        );
    }

    /*** INDEX METHODS ******************************************************/

    function createIndex(
        required name,
        body="",
        ignore=""        
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(name),
            body=body,
            ignore=ignore
        );
    }

    function deleteIndex(
        required name,
        ignore=""        
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(name),
            ignore=ignore
        );
    }

    function indexExists(
        required name
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(name),
            ignore="404"
        ).is200();
    }

    function refreshIndex(
        name="",
        ignore=""        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(name, "_refresh"),
            ignore=ignore
        );
    }

    /*** ALIAS METHODS ******************************************************/

    function createAlias(
        required name,
        required index,
        ignore=""        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"add"= {"index"=index, "alias"=name}}
                ]
            },
            ignore=ignore
        );
    }

    function removeAlias(
        required name,
        index="_all",
        ignore=""        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"remove"= {"index"=index, "alias"=name}}
                ]
            },
            ignore=ignore
        );
    }

    function changeAlias(
        required name,
        required index,
        previousIndex="_all",
        ignore=""        
    ) {
        return updateAliases(
            [
                {"remove" = {"index"=previousIndex, "alias"=name}},
                {"add" = {"index"=index, "alias"=name}}
            ],
            ignore=ignore
        );
    }

    function updateAliases(
        required actions,
        ignore=""        
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=actions
            },
            ignore=ignore
        );
    }

    function getAlias(
        index="",
        alias="",
        ignore=""
    ) {
        return makeHttpRequest(
            method="get",
            url=createUrl(index, "_alias", alias),
            ignore=ignore
        );
    }

    function aliasExists(
        required name,
        index=""
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, "_alias", name),
            ignore="404"
        ).is200();
    }

    /*** DOCUMENT METHODS ***************************************************/

    function insertDocument(
        required index,
        required type,
        required id,
        required body,
        ignore=""
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(index, type, id),
            body=body,
            ignore=ignore
        );
    }

    function updateDocument(
        required index,
        required type,
        required id,
        required body,
        ignore=""
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, id, "_update"),
            body=body,
            ignore=ignore
        );
    }

    function documentExists(
        required index,
        required type,
        required id
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, type, id),
            ignore="404"
        ).is200();
    }

    function removeDocument(
        required index,
        required type,
        required id,
        ignore=""
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(index, type, id),
            ignore=ignore
        );
    }

    /*** BULK ***************************************************************/

    function bulk(
        required actions,
        index="",
        type="",
        ignore=""
    ) {
        for (var i=1; i lte arrayLen(actions); i++) {
            if (not isJSON(actions[i])) actions[i] = serializeJSON(actions[i]);
        }

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_bulk"),
            body=arrayToList(actions, "#chr(10)#") & "#chr(10)#",
            ignore=ignore
        );
    }

    function searchAndReplace(
        required index,
        required type,
        required body,
        required fields,
        required oldValue,
        required newValue,
        ignore=""
    ) {
        var scroll_id = search(
            index=index,
            type=type,
            body=body,
            params={
                "search_type"="scan",
                "scroll"="5m"
            }
        ).toJSON()["_scroll_id"];

        var results = searchScroll(scroll="5m", scroll_id=scroll_id).toJSON();

        while (arrayLen(results["hits"]["hits"])) {
            var actions = [];

            for (var i=1; i lt arrayLen(results["hits"]["hits"]); i++) {
                var record = results["hits"]["hits"][i];

                var updatedDoc = {};

                for (var field in listToArray(fields)) {
                    if (structKeyExists(record["_source"], field)) {
                        updatedDoc[field] = replace(record["_source"][field], oldValue, newValue);
                    }
                }

                arrayAppend(actions, { "update"={ "_id"= record["_source"]["contentID"] } });
                arrayAppend(actions, { "doc"=updatedDoc });
            }

            elasticsearch.bulk(
                actions=actions,
                index=index,
                type=getMuraContentType(),
                ignore=ignore
            );

            var results = elasticsearch.searchScroll(scroll="5m", scroll_id=scroll_id).toJSON();
        }
    }
 
    /*** PRIVATE METHODS ****************************************************/

    private function createUrl() {
        var href = getHost();

        for(var param in arguments) {
            if(len(arguments[param])) { href = listAppend(href, arguments[param], "/"); }
        }

        return href;
    }

    private function makeHttpRequest() {
        response = getHttpRequestService().request(argumentCollection=arguments, throwOnError=false); 

        // TODO log request was made

        if (
            not (response.getStatusCode() >= 200 and response.getStatusCode() < 300)
            and not listFindNoCase(response.getStatusCode(), arguments.ignore)
        ) {
            // TODO log that request failed
            raiseError(response);
        }

        return response;
    }

    HTTP_ERRORS = {
        0   = "elasticsearch.TransportError.ConnectionError",
        400 = "elasticsearch.TransportError.RequestError",
        404 = "elasticsearch.TransportError.NotFoundError",
        409 = "elasticsearch.TransportError.ConflictError"
    };

    private function raiseError(required response) {
        var responseJSON = response.toJSON();

        var errorType = (
            structkeyexists(HTTP_ERRORS, response.getStatusCode())
                ? HTTP_ERRORS[response.getStatusCode()]
                : "elasticsearch.TransportError")

        var errorDetail = (
            isstruct(responseJSON) and structkeyexists(responseJSON, "error")
                ? responseJSON.error
                : "");

        throw(
            type=errorType,
            message=errorType,
            detail=errorDetail,
            extendedInfo=response.toString(),
            code=response.getStatusCodeString()
        );
    }

    private function structToQueryString(required structure) {
        var queryString = "";
        for (var key in structure) {
            queryString = listAppend(queryString, URLEncodedFormat(lcase(key)) & "=" & URLEncodedFormat(structure[key]), "&");
        }
        return "?" & queryString;
    }

}