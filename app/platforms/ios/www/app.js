(function() {
  var Sockets;

  window.app = {
    currentView: null,
    debug: (function(_this) {
      return function() {
        return console.log(arguments);
      };
    })(this),
    init: (function(_this) {
      return function() {
        _this.bindEvents();
        return true;
      };
    })(this),
    bindEvents: (function(_this) {
      return function() {
        document.addEventListener("load", _this.onLoad, false);
        document.addEventListener("deviceready", _this.onDeviceReady, false);
        document.addEventListener("online", _this.onOnline, false);
        return document.addEventListener("offline", _this.onOffline, false);
      };
    })(this),
    onLoad: (function(_this) {
      return function() {
        return _this.debug("Event: load");
      };
    })(this),
    onDeviceReady: (function(_this) {
      return function() {
        _this.debug("Event: deviceReady");
        if (localStorage.getItem("homeserver.host") == null) {
          return _this.navigate("settings");
        } else {
          return _this.navigate("home");
        }
      };
    })(this),
    onOnline: (function(_this) {
      return function() {
        return _this.debug("Event: online");
      };
    })(this),
    onOffline: (function(_this) {
      return function() {
        return _this.debug("Event: offline");
      };
    })(this),
    navigate: (function(_this) {
      return function(id, back) {
        var direction;
        if (_this.currentView != null) {
          _this.currentView.dispose();
        }
        direction = back ? "right" : "left";
        return window.plugins.nativepagetransitions.slide({
          direction: direction,
          href: "#" + id
        }, function() {
          _this.currentView = window["" + id + "View"];
          return _this.currentView.init();
        });
      };
    })(this)
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

  window.settingsView = {
    el: "#settings",
    init: (function(_this) {
      return function() {
        return _this.el.find("input.host").focus();
      };
    })(this),
    dispose: (function(_this) {
      return function() {
        return app.debug(_this.el, "Disposed");
      };
    })(this)
  };

}).call(this);
