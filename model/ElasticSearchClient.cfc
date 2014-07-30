component accessors=true {
    property name="Host";
    property name="HttpRequestService";

    function search(
        required body,
        index="",
        type="",
        params=""
    ) {
        if (not len(index) and len(type)) index = "*";

        if (isStruct(params)) params = structToQueryString(params);

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_search") & params,
            body=body
        );
    }

    function searchScroll(
        required scroll,
        required scroll_id
    ) {
        return makeHttpRequest(
            method="get",
            url=createURL("_search", "scroll") & structToQueryString(arguments)
        );
    }

    /*** INDEX METHODS ******************************************************/

    function createIndex(
        required name,
        body=""
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(name),
            body=body
        );
    }

    function deleteIndex(
        required name
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(name)
        );
    }

    function indexExists(
        required name
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(name)
        ).getStatusCode() eq 200;
    }

    function refreshIndex(
        name=""
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(name, "_refresh")
        );
    }

    /*** ALIAS METHODS ******************************************************/

    function createAlias(
        required name,
        required index
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"add"= {"index"=index, "alias"=name}}
                ]
            }
        );
    }

    function removeAlias(
        required name,
        index="_all"
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=[
                    {"remove"= {"index"=index, "alias"=name}}
                ]
            }
        );
    }

    function changeAlias(
        required name,
        required index,
        previousIndex="_all"
    ) {
        return updateAliases([
            {"remove" = {"index"=previousIndex, "alias"=name}},
            {"add" = {"index"=index, "alias"=name}}
        ]);
    }

    function updateAliases(required actions) {
        return makeHttpRequest(
            method="post",
            url=createUrl("_aliases"),
            body={
                "actions"=actions
            }
        );
    }

    function getAlias(
        index="",
        alias=""
    ) {
        return makeHttpRequest(
            method="get",
            url=createUrl(index, "_alias", alias)
        );
    }

    function aliasExists(
        required name,
        index=""
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, "_alias", name)
        ).getStatusCode() eq 200;
    }

    /*** DOCUMENT METHODS ***************************************************/

    function insertDocument(
        required index,
        required type,
        required id,
        required body
    ) {
        return makeHttpRequest(
            method="put",
            url=createUrl(index, type, id),
            body=body
        );
    }

    function updateDocument(
        required index,
        required type,
        required id,
        required body
    ) {
        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, id, "_update"),
            body=body
        );
    }

    function documentExists(
        required index,
        required type,
        required id
    ) {
        return makeHttpRequest(
            method="head",
            url=createUrl(index, type, id)
        ).getStatusCode() eq 200;
    }

    function removeDocument(
        required index,
        required type,
        required id
    ) {
        return makeHttpRequest(
            method="delete",
            url=createUrl(index, type, id)
        );
    }

    /*** BULK ***************************************************************/

    function bulk(
        required actions,
        index="",
        type=""
    ) {
        for (var i=1; i lte arrayLen(actions); i++) {
            if (not isJSON(actions[i])) actions[i] = serializeJSON(actions[i]);
        }

        return makeHttpRequest(
            method="post",
            url=createUrl(index, type, "_bulk"),
            body=arrayToList(actions, "#chr(10)#") & "#chr(10)#"
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
        return getHttpRequestService().request(argumentCollection=arguments);
    }

    private function structToQueryString(required structure) {
        var queryString = "";
        for (var key in structure) {
            listAppend(queryString, URLEncodedFormat(lcase(key)) & "=" & URLEncodedFormat(structure[key]), "&");
        }
        return "?" & queryString;
    }

}