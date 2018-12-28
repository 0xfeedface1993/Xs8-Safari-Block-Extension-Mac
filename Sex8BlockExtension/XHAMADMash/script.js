document.addEventListener("DOMContentLoaded", function(event) {
    safari.extension.dispatchMessage("Hello World!");
    safari.self.addEventListener("message", handleMessage);
});

function handleMessage(event) {
    console.log(event.name);
    console.log(event.message);
    document.getElementById('bt2').value = 'Hide Ad';
    document.getElementById('sub4').style.display = 'none';
    document.getElementById('bt2').value = 'Hide Ad';
    document.getElementById('sub3').style.display = 'none';
}
