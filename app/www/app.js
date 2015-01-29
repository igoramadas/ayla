(function() {
  var App, HomeView, SettingsView, Sockets,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  App = (function() {
    function App() {
      this.navigate = __bind(this.navigate, this);
      this.onOffline = __bind(this.onOffline, this);
      this.onOnline = __bind(this.onOnline, this);
      this.onDeviceReady = __bind(this.onDeviceReady, this);
      this.onLoad = __bind(this.onLoad, this);
      this.bindNavigation = __bind(this.bindNavigation, this);
      this.bindEvents = __bind(this.bindEvents, this);
      this.init = __bind(this.init, this);
      this.debug = __bind(this.debug, this);
    }

    App.prototype.currentView = null;

    App.prototype.debug = function() {
      return console.log(arguments);
    };

    App.prototype.init = function() {
      this.bindEvents();
      return this.bindNavigation();
    };

    App.prototype.bindEvents = function() {
      if (document.URL.indexOf("http://") < 0) {
        document.addEventListener("load", this.onLoad, false);
        document.addEventListener("deviceready", this.onDeviceReady, false);
        document.addEventListener("online", this.onOnline, false);
        return document.addEventListener("offline", this.onOffline, false);
      } else {
        return this.onDeviceReady();
      }
    };

    App.prototype.bindNavigation = function() {
      return $(".icon-bar a").click((function(_this) {
        return function(e) {
          var src;
          src = $(e.currentTarget);
          return _this.navigate(src.data("view"));
        };
      })(this));
    };

    App.prototype.onLoad = function() {
      return this.debug("Event: load");
    };

    App.prototype.onDeviceReady = function() {
      this.debug("Event: deviceReady");
      if (localStorage.getItem("homeserver_url") != null) {
        this.navigate("home");
      } else {
        this.navigate("settings");
      }
      $(document).foundation();
      pager.extendWithPage(this);
      ko.applyBindings(this);
      return pager.start();
    };

    App.prototype.onOnline = function() {
      return this.debug("Event: online");
    };

    App.prototype.onOffline = function() {
      return this.debug("Event: offline");
    };

    App.prototype.navigate = function(id, callback) {
      this.debug("Navigate: " + id);
      if (this.currentView != null) {
        this.currentView.el.hide();
        this.currentView.dispose();
      }
      this.currentView = window["" + id + "View"];
      this.currentView.el = $("#" + id);
      this.currentView.el.show();
      return this.currentView.init();
    };

    return App;

  })();

  window.app = new App();

  Sockets = (function() {
    var conn;

    function Sockets() {}

    conn = null;

    Sockets.prototype.init = function() {
      var url;
      url = localStorage.getItem("homeserver_url");
      if (url != null) {
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

  window.sockets = new Sockets();

  HomeView = (function() {
    function HomeView() {
      this.dispose = __bind(this.dispose, this);
      this.init = __bind(this.init, this);
    }

    HomeView.prototype.init = function() {
      return this.el.find("input.host").focus();
    };

    HomeView.prototype.dispose = function() {};

    return HomeView;

  })();

  window.homeView = new HomeView();

  SettingsView = (function() {
    function SettingsView() {
      this.saveClick = __bind(this.saveClick, this);
      this.dispose = __bind(this.dispose, this);
      this.init = __bind(this.init, this);
    }

    SettingsView.prototype.init = function() {
      return this.el.find("button.save").click;
    };

    SettingsView.prototype.dispose = function() {};

    SettingsView.prototype.saveClick = function(e) {
      var host, port, token;
      host = this.el.find("input.host").val();
      port = this.el.find("input.port").val();
      token = this.el.find("input.token").val();
      localStorage.setItem("homeserver_url", "https://" + host + ":" + port + "/");
      return localStorage.setItem("homeserver_token", token);
    };

    return SettingsView;

  })();

  window.settingsView = new SettingsView();

}).call(this);
