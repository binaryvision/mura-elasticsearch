component accessors=true {
    this.DATE_FORMAT = "yyyy-MM-dd";
    this.DATETIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";

    dateFormatter = createObject("java", "java.text.SimpleDateFormat").init(this.DATE_FORMAT);
    datetimeFormatter = createObject("java", "java.text.SimpleDateFormat").init(this.DATETIME_FORMAT);

    function parseDate(required datetimeString) {
        return dateFormatter.parse(datetimeString);
    }

    function parseDatetime(required datetimeString) {
        return datetimeFormatter.parse(datetimeString);
    }

    function formatDate(required datetime) {
        return dateFormatter.format(datetime);
    }

    function formatDatetime(required datetime) {
        return datetimeFormatter.format(datetime);
    }

}