(function() {
  var Sockets, app;

  app = {
    initialize: function() {
      this.bindEvents();
    },
    bindEvents: function() {
      document.addEventListener("load", this.onLoad, false);
      document.addEventListener("deviceready", this.onDeviceReady, false);
      document.addEventListener("online", this.onOnline, false);
      document.addEventListener("offline", this.onOffline, false);
    },
    onLoad: function() {},
    onDeviceReady: function() {
      app.receivedEvent("deviceready");
    },
    onOnline: function() {},
    onOffline: function() {},
    receivedEvent: function(id) {
      var listeningElement, parentElement, receivedElement;
      parentElement = document.getElementById(id);
      listeningElement = parentElement.querySelector(".listening");
      receivedElement = parentElement.querySelector(".received");
      listeningElement.setAttribute("style", "display:none;");
      receivedElement.setAttribute("style", "display:block;");
      console.log("Received Event: " + id);
    }
  };

  Sockets = (function() {
    var conn;

    function Sockets() {}

    conn = null;

    Sockets.prototype.init = function() {
      var url;
      if (conn == null) {
        url = window.location;
        return conn = io.connect("" + url.protocol + "//" + url.hostname + ":" + url.port);
      }
    };

    Sockets.prototype.stop = function() {
      return conn.off();
    };

    Sockets.prototype.on = function(event, callback) {
      return conn.on(event, callback);
    };

    Sockets.prototype.off = function(event, callback) {
      return conn.off(event, callback);
    };

    Sockets.prototype.emit = function(event, data) {
      return conn.emit(event, data);
    };

    return Sockets;

  })();

  window.ayla.sockets = new Sockets();

}).call(this);
