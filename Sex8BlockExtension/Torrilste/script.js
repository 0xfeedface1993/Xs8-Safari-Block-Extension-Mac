document.addEventListener("DOMContentLoaded", function(event) {
    safari.extension.dispatchMessage("Hello World!");
    safari.self.addEventListener("message", handleMessage);
    addMyNotification()
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
                var locationURL = document.location.href;
                if (validateA && validateA.length > 0) {
                    safari.extension.dispatchMessage("CatchDownloadLinks", {"links":validateA, "passwod":code, "title":titlex, "pics":pics, "fileName":fileName, "url":locationURL});
                }   else    {
                    showErrorNotification("数据为空");
                }
            }   else    {
                console.log("空空如也");
                showErrorNotification("空空如也");
            }
        break;
    case "saveOK":
            showMyNotification("保存成功");
            break;
    case "notOK":
            showErrorNotification("保存失败");
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
            if (aTag.childElementCount > 0) {
                continue;
            }
            console.log(aTag);
            var hrefx = aTag.getAttribute('href');
            if (hrefx.indexOf("http://") >= 0) {
                validateA.push(hrefx);
//                alert(hrefx);
            }
        }
    }
    var gm = parentDode[0].getElementsByTagName("blockquote");
    if (gm != null && gm.length > 0) {
        for (var j = 0; j < gm.length; j++) {
            var link = gm[j];
            validateA.push(link.innerHTML);
//            alert(link.innerHTML);
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
//                    alert(link.innerHTML);
                }
            }
        }
    }
    
    var vle = parentDode[0].getElementsByTagName("ol");
    if (vle != null && vle.length > 0) {
        for (var j = 0; j < vle.length; j++) {
            var link = vle[j];
            var aLink = link.getElementsByTagName('li');
            if (aLink != null && aLink.length > 0) {
                for (var k = 0;k<aLink.length;k++){
                    var item = aLink[k];
                    if (item.innerHTML.indexOf("http://") >= 0) {
                        validateA.push(item.innerHTML);
//                        alert(item.innerHTML);
                    }
                }
            }
        }
    }
    
    var fonts = parentDode[0].getElementsByTagName('font');
    if (fonts != null && fonts.length > 0) {
        for (var j = 0; j < fonts.length; j++) {
            var ft = fonts[j];
            if (ft.innerHTML.indexOf("http://") >= 0) {
                validateA.push(ft.innerHTML);
            }
        }
    }
    
    return validateA;
}


// 获取解压密码
function getPassword(parentDode) {
    var dooms = parentDode[0].innerHTML;
    var prefixs = ["【解压密码】：", "【解壓密碼】: ", "【解壓密碼】：", "【解压密码】"]
    for (var j = 0; j < prefixs.length; j++) {
        var prefix = prefixs[j];
        var pIndex = dooms.indexOf(prefix);
        if (pIndex >= 0) {
            var sub = dooms.slice(pIndex);
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
    var dooms = parentDode[0].innerHTML.replace(/[\r\n]/g, "");
    var prefixs = ["【下载地址】", "【下载链接】"]
    for (var j = 0; j < prefixs.length; j++) {
        var prefix = prefixs[j];
        var pIndex = dooms.indexOf(prefix);
        if (pIndex >= 0) {
            var sub = dooms.slice(pIndex + prefix.length);
            var fileTypes = [".rar", ".zip"];
            for (var k = 0;k<fileTypes.length;k++) {
                var type = fileTypes[k];
                var typeLength = type.length;
                var typeIndex = sub.indexOf(type);
                if(typeIndex >= 0){
                    var beforeSub = sub.substring(0, typeIndex);
                    var fileNameSub = deleteBrTagText(beforeSub);
                    return fileNameSub == "" ? null:fileNameSub + type;
                }
            }
        }
    }
    return null;
}

function deleteBrTagText(rawText){
    var bIndex = rawText.indexOf(">");
    if (bIndex >= 0) {
        return deleteBrTagText(rawText.slice(bIndex + 1));
    }   else    {
        return rawText.replace(/[:： ]/g, "");
    }
}

// 淡入淡出动画

function addMyNotification() {
    var nod = document.createElement("style"),
    str = ".xts-notifier-center {position: fixed;text-align: center;font-weight: bold;color: white;height: 26px;width: 80px;top: 0%;left: 0%;margin-left: 40px;margin-top: 20px;border-radius: 6px;opacity: 0.0;z-index: 9999;font-size: 14px;align-content: center;-webkit-animation-name: xtsfadeIn;-webkit-animation-duration: 2s; -webkit-animation-iteration-count: 1; -webkit-animation-delay: 0s; -webkit-animation-timing-function: ease-in;}.xts-notifier-center-hide {opacity: 0.0;}@-webkit-keyframes xtsfadeIn {0% {opacity: 0;}50% {opacity: 1;}100% {opacity: 0; }}.xts-black {background: black;}.xts-red {background: red;}";
    nod.type="text/css";
    if(nod.styleSheet){         //ie下
        nod.styleSheet.cssText = str;
    } else {
        nod.innerHTML = str;       //或者写成 nod.appendChild(document.createTextNode(str))
    }
    document.body.appendChild(nod);
    
    var notitier = document.createElement("div");
    notitier.id = "xts-notifer";//
    notitier.className = "xts-notifier-center-hide";
    notitier.innerHTML = "<span id='xts-notifer-content'>未知</span>";
    document.body.appendChild(notitier);
}

function showMyNotification(info) {
    document.getElementById('xts-notifer-content').innerHTML = info;
    document.getElementById('xts-notifer').className = "xts-notifier-center xts-red";
    setTimeout(function(){
               document.getElementById('xts-notifer').className = "xts-notifier-center-hide";
               document.getElementById('xts-notifer-content').innerHTML = "未知";
               }, 2100);
}

function showErrorNotification(info) {
    document.getElementById('xts-notifer-content').innerHTML = info;
    document.getElementById('xts-notifer').className = "xts-notifier-center xts-black";
    setTimeout(function(){
               document.getElementById('xts-notifer').className = "xts-notifier-center-hide";
               document.getElementById('xts-notifer-content').innerHTML = "未知";
               }, 2100);
}
