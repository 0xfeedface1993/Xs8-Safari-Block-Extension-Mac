document.addEventListener("DOMContentLoaded", function(event) {
    safari.extension.dispatchMessage("Hello World!");
                          safari.self.addEventListener("download", function (event){
                                                       window.location.href = document.getElementsByTagName('ignore_js_op')[0].getElementsByTagName('span')[0].getElementsByTagName('a')[0].getAttribute('href');
                                                       safari.extension.dispatchMessage(window.location.href);
                                                       });
});

