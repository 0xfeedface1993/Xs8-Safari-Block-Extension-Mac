document.addEventListener("DOMContentLoaded", function(event) {
    safari.extension.dispatchMessage("Hello World!");
    safari.self.addEventListener("message", handleMessage);
});

function handleMessage(event) {
    console.log(event.name);
    console.log(event.message);
    console.log(document.body);
    switch (event.name) {
    case "copyDonloadLink":
            var blocks = document.getElementsByClassName('t_f');
            if (blocks != null && blocks.length > 0) {
                var validateA = getDownloadLinks(blocks);
                var pics = getPictureURLs(blocks);
                var code = getPassword(blocks);
                code = code == null ? "未查询到密码":code;
                var fileName = getFileName(blocks);
                fileName = fileName == null ? "未查询到文件名":fileName;
                var titlex = document.getElementById("thread_subject").innerHTML;
                if (validateA && validateA.length > 0) {
                    safari.extension.dispatchMessage("CatchDownloadLinks", {"links":validateA, "passwod":code, "title":titlex, "pics":pics, "fileName":fileName});
                }
            }   else    {
                console.log("空空如也");
            }
        break;
    default:
        break;
    }
}

// 获取下载地址链接
function getDownloadLinks(parentDode) {
    var validateA = [];
    var dooms = parentDode[0].getElementsByTagName('a');
    if (dooms != null && dooms.length > 0) {
        console.log(dooms);
        for (var j = 0; j < dooms.length; j++) {
            var aTag = dooms[j];
            console.log(aTag);
            var hrefx = aTag.getAttribute('href');
            if (hrefx.indexOf("http://") >= 0) {
                validateA.push(hrefx);
                alert(hrefx);
            }
        }
    }
    var gm = parentDode[0].getElementsByTagName("blockquote");
    if (gm != null && gm.length > 0) {
        for (var j = 0; j < gm.length; j++) {
            var link = gm[j];
            validateA.push(link.innerHTML);
            alert(link.innerHTML);
        }
    }
    
    var aks = parentDode[0].getElementsByTagName("font");
    if (aks != null && aks.length > 0) {
        for (var j = 0; j < aks.length; j++) {
            var link = aks[j];
            var aLink = link.getElementsByTagName('a');
            var nodes = link.childNodes.length;
            if (!(aLink != null && aLink.length > 0) && nodes <= 0) {
                if (link.innerHTML.indexOf("http://") >= 0) {
                    validateA.push(link.innerHTML);
                    alert(link.innerHTML);
                }
            }
        }
    }
    
    return validateA;
}


// 获取解压密码
function getPassword(parentDode) {
    var dooms = parentDode[0].innerHTML;
    var prefixs = ["【解压密码】：", "【解壓密碼】: ", "【解壓密碼】："]
    for (var j = 0; j < prefixs.length; j++) {
        var prefix = prefixs[j];
        var pIndex = dooms.indexOf(prefix);
        if (pIndex >= 0) {
            var sub = dooms.slice(pIndex);
//            var brText = "<br>";
            var brText = "<";
            var brLength = brText.length;
            var pLength = prefix.length;
            var brBreakIndex = sub.indexOf(brText);
            if (brBreakIndex >= 0) {
                var code = sub.substring(pLength, brBreakIndex);
                return code;
            }   else    {
                var code = sub.substring(pLength);
                return code;
            }
        }
    }
    return null;
}

// 获取预览图片url
function getPictureURLs(parentDode) {
    var dooms = parentDode[0].getElementsByClassName('zoom');
    var links = [];
    for (var j = 0; j < dooms.length; j++) {
        var imgx = dooms[j];
        var src = imgx.getAttribute("src");
        var style = imgx.getAttribute("style");
        if (src != null) {
            links.push(src);
        }
    }
    return links;
}

// 获取文件名
function getFileName(parentDode) {
    var dooms = parentDode[0].innerHTML;
    var prefixs = ["【下载链接】"]
    for (var j = 0; j < prefixs.length; j++) {
        var prefix = prefixs[j];
        var pIndex = dooms.indexOf(prefix);
        if (pIndex >= 0) {
            var sub = dooms.slice(pIndex);
            //            var brText = "<br>";
            var brText = "<";
            var brLength = brText.length;
            var pLength = prefix.length;
            var brBreakIndex = sub.indexOf(brText);
            if (brBreakIndex >= 0) {
                var code = sub.substring(pLength, brBreakIndex).replace(/：/, "");
                return code;
            }   else    {
                var code = sub.substring(pLength).replace(/：/, "");
                return code;
            }
        }
    }
    return null;
}


