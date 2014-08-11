component accessors=true {
    property name="beanFactory";

    function getIndexSettings() {
        return fileRead("indexSettings.json"); // if extended in a theme where will this look?
    }

    function shouldIndex(required content) {
        return true; // forgot to set my generated content to display=true
        //return content.getIsOnDisplay() and not content.getSearchExclude();
    }

    function contentToJSON(required content) {
        writeDump(serializeJSON(contentToStruct(content)));
        return serializeJSON(contentToStruct(content));
    }

    function contentToStruct(required content) {
        return {
            "contentID"=content.getContentID(),
            "title"=content.getTitle(),
            "path"=content.getPath(),
            "type"=content.getType(),
            "subType"=content.getSubType(),
            "body"=content.getBody(),
            "summary"=content.getSummary(),
            "file"=(
                (len(content.getFileID()) and content.getType().equalsIgnoreCase("file"))
                    ? binaryEncode(fileReadBinary(getPathToAssociatedFile(content)), "base64")
                    : ""
            ),
            "tags"=listToArray(content.getTags()),
            "url"=content.getUrl(),
            "created"=elasticsearchDatetime(content.getCreated()),
            "lastUpdate"=elasticsearchDatetime(content.getLastUpdate()),
            "metaDesc"=content.getMetaDesc(),
            "metaKeywords"=content.getMetaKeywords(),
            "filename"=content.getFilename()
        };
    }

    private function getPathToAssociatedFile(required content) {
        getBeanFactory().getMuraService().getPathToAssociatedFile(content);
    }

    private function elasticsearchDate(required datetime) {
        return dateFormat(datetime, "YYYYMMDD");
    }

    private function elasticsearchDatetime(required datetime) {
        return elasticsearchDate(datetime) & "T" & timeFormat(datetime, "HHMMSS");
    } 

}