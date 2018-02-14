document.addEventListener("DOMContentLoaded", function(event) {
                          safari.extension.dispatchMessage("Hello World!");
                          safari.self.addEventListener("message", handleMessage);
                          addMyNotification();
});

function handleMessage(event) {
    console.log(event.name);
    console.log(event.message);
    switch (event.name) {
        case "copyDonloadLink":
            var list = grepPageData();
            if (list != null) {
                safari.extension.dispatchMessage("CatchDownloadLinks", list);
            }
            break;
        case "saveOK":
            showMyNotification("保存成功");
            break;
        case "notOK":
            showErrorNotification("保存失败");
            break;
        case "getFullHtml":
            safari.extension.dispatchMessage("getFullHtml", getFullHtml());
            break;
        default:
            break;
    }
}
