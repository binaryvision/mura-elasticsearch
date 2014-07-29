component {

    function getIndexSettings() {
        return fileRead("indexSettings.json"); // if extended in a theme where will this look?
    }

    function shouldIndex(required content) {
        return content.getIsOnDisplay() and not content.getSearchExclude();
    }

    function contentToJSON(required content) {
        return serializeJSON(contentToStruct(content));
    }

    function contentToStruct(required content) {
        return {
            "title"=content.getTitle(),
            "path"=content.getPath(),
            "type"=content.getType(),
            "subType"=content.getSubType(),
            "body"=content.getBody(),
            "summary"=content.getSummary(),
            "file"=(
                len(content.getFileID())
                    ? binaryEncode(fileReadBinary(getPathToAssociatedFile(content)), "base64")
                    : ""
            ),
            "tags"=listToArray(content.getTags()),
            "url"=content.getUrl(),
            "created"=content.getCreated(),
            "lastUpdate"=content.getLastUpdate(),
            "metaDesc"=content.getMetaDesc(),
            "metaKeywords"=content.getMetaKeywords()
        };
    }

}