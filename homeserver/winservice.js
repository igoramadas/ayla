// Helper to install a Windows Service for Ayla.
// Depends on node-windows.
var Service = require("node-windows").Service;

// Create a new service object.
var svc = new Service({
    name:"Ayla Home Server",
    description: "Ayla homeserver (Node.js app).",
    script: "D:\\Ayla\\homeserver\\index.js",
    env: {
        name: "NODE_ENV",
        value: "production"
    }
});

// Listen for the "install" event, which indicates the
// process is available as a service.
svc.on("install", function(){
    svc.start();
});

svc.install();
