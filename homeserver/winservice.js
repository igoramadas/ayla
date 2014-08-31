var Service = require("node-windows").Service;

// Create a new service object.
var svc = new Service({
    name:"Ayla Home Server",
    description: "Ayla homeserver (Node.js app).",
    script: "D:\\Ayla\\homeserver\\index.js"
});

// Listen for the "install" event, which indicates the
// process is available as a service.
svc.on("install", function(){
    svc.start();
});

svc.install();
