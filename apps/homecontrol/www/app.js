(function() {
  var App, LightsView, SettingsView, Sockets, WeatherView,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  App = (function() {
    function App() {
      this.notify = __bind(this.notify, this);
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
      var _ref;
      this.debug("Event: deviceReady");
      if (((_ref = localStorage.getItem("homeserver_url")) != null ? _ref.toString().length : void 0) > 11) {
        this.navigate("settings");
      } else {
        this.navigate("settings");
      }
      return $(document).foundation();
    };

    App.prototype.onOnline = function() {
      return this.debug("Event: online");
    };

    App.prototype.onOffline = function() {
      return this.debug("Event: offline");
    };

    App.prototype.navigate = function(id, callback) {
      var socketsId;
      this.debug("Navigate: " + id);
      socketsId = id.charAt(0).toUpperCase() + id.slice(1) + "Manager.data";
      $("a.item").removeClass("active");
      $("a.item." + id).addClass("active");
      if (this.currentView != null) {
        if (this.currentView.processData != null) {
          sockets.off("" + socketsId, this.currentView.processData);
        }
        this.currentView.el.hide();
        this.currentView.dispose();
      }
      this.currentView = window["" + id + "View"];
      this.currentView.el = $("#" + id);
      this.currentView.el.show();
      this.currentView.init();
      if (this.currentView.processData != null) {
        return sockets.on("" + socketsId, this.currentView.processData);
      }
    };

    App.prototype.notify = function(message) {
      return this.debug("Notify", message);
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

  LightsView = (function() {
    function LightsView() {
      this.ninjaLightToggle = __bind(this.ninjaLightToggle, this);
      this.hueLightToggle = __bind(this.hueLightToggle, this);
      this.hueLightColor = __bind(this.hueLightColor, this);
      this.dispose = __bind(this.dispose, this);
      this.init = __bind(this.init, this);
    }

    LightsView.prototype.init = function() {};

    LightsView.prototype.dispose = function() {};

    LightsView.prototype.hueLightColor = function(light, e) {
      var data;
      data = {
        lightId: light.id,
        title: light.title,
        colorHex: $(e.target).val()
      };
      sockets.emit("LightsManager.Hue.color", data);
      return true;
    };

    LightsView.prototype.hueLightToggle = function(light, e) {
      var data;
      light.state = $(e.target).is(":checked");
      data = {
        lightId: light.id,
        title: light.title,
        state: light.state
      };
      sockets.emit("LightsManager.Hue.toggle", data);
      return true;
    };

    LightsView.prototype.ninjaLightToggle = function(light, e) {
      var code, data;
      code = $(e.target).hasClass("success") ? light.codeOn : light.codeOff;
      data = {
        title: light.title,
        code: code
      };
      sockets.emit("LightsManager.Ninja.toggle", data);
      return true;
    };

    return LightsView;

  })();

  window.lightsView = new LightsView();

  SettingsView = (function() {
    function SettingsView() {
      this.saveClick = __bind(this.saveClick, this);
      this.dispose = __bind(this.dispose, this);
      this.init = __bind(this.init, this);
    }

    SettingsView.prototype.init = function() {
      return this.el.find("form").on("valid", this.saveClick);
    };

    SettingsView.prototype.dispose = function() {};

    SettingsView.prototype.saveClick = function(e) {
      var host, port, serverResult, token, url, xhr;
      serverResult = this.el.find(".server-result");
      host = this.el.find("input.host").val();
      port = this.el.find("input.port").val();
      token = this.el.find("input.token").val();
      url = "http://" + host + ":" + port + "/tokenrequest?token=" + token;
      xhr = $.getJSON(url, (function(_this) {
        return function(data) {
          if (data.error != null) {
            return serverResult.html("Invalid token or server details.");
          } else {
            localStorage.setItem("homeserver_url", "https://" + host + ":" + port + "/");
            localStorage.setItem("homeserver_token", token);
            return serverResult.html("Authenticated till " + data.result.expires);
          }
        };
      })(this));
      return xhr.fail((function(_this) {
        return function() {
          return serverResult.html("Could not contact the specified server.");
        };
      })(this));
    };

    return SettingsView;

  })();

  window.settingsView = new SettingsView();

  WeatherView = (function() {
    function WeatherView() {
      this.toggleChart = __bind(this.toggleChart, this);
      this.createChart = __bind(this.createChart, this);
      this.modelProcessor = __bind(this.modelProcessor, this);
      this.onDispose = __bind(this.onDispose, this);
      this.onReady = __bind(this.onReady, this);
    }

    WeatherView.prototype.viewId = "Weather";

    WeatherView.prototype.onReady = function() {
      var _base, _base1, _base2;
      logger("Loaded Weather View");
      $(".outside .panel").click(this.toggleChart);
      if ((typeof (_base = this.model).outside === "function" ? _base.outside().temperature : void 0) == null) {
        this.model.outside().temperature = this.model.forecastCurrent().temperature;
      }
      if ((typeof (_base1 = this.model).outside === "function" ? _base1.outside().humidity : void 0) == null) {
        this.model.outside().humidity = this.model.forecastCurrent().humidity;
      }
      if ((typeof (_base2 = this.model).outside === "function" ? _base2.outside().precp : void 0) == null) {
        this.model.outside().precp = 0;
      }
      return this.model.outside(this.model.outside());
    };

    WeatherView.prototype.onDispose = function() {
      return $(".outside .panel").unbind("click", this.toggleChart);
    };

    WeatherView.prototype.modelProcessor = function(key, data) {
      var climate, co2, co2Count, condition, humidity, humidityCount, room, roomInfo, temp, tempCount, _i, _len, _ref;
      if (data == null) {
        data = key;
        key = null;
      }
      if (this.model.indoorAvg == null) {
        this.model.indoorAvg = ko.observable();
      }
      if (data.condition != null) {
        condition = _.isFunction(data.condition) ? data.condition() : data.condition;
        data.conditionCss = ko.computed(function() {
          return condition.toLowerCase().replace(/\s/g, "-").replace(",-", " ");
        });
      }
      if (key === "forecastDays") {
        _.delay(this.createChart, 300, data);
      }
      if (key === "forecastCurrent") {
        $("#wrapper").removeClass();
        $("#wrapper").addClass(data.icon);
      }
      if (this.model.rooms == null) {
        return;
      }
      temp = 0;
      tempCount = 0;
      humidity = 0;
      humidityCount = 0;
      co2 = 0;
      co2Count = 0;
      _ref = this.model.rooms();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        roomInfo = _ref[_i];
        room = this.model[roomInfo.id];
        if (room != null) {
          room = room();
          climate = room.climate;
          if (climate.temperature != null) {
            temp += parseFloat(climate.temperature);
            tempCount++;
          }
          if (climate.humidity != null) {
            humidity += parseFloat(climate.humidity);
            humidityCount++;
          }
          if (climate.co2 != null) {
            co2 += parseFloat(climate.co2);
            co2Count++;
          }
        }
      }
      if (tempCount === 0) {
        tempCount = 1;
      }
      if (humidityCount === 0) {
        humidityCount = 1;
      }
      if (co2Count === 0) {
        co2Count = 1;
      }
      if (tempCount > 0 && humidityCount > 0) {
        temp = (temp / tempCount).toFixed(1);
        humidity = (humidity / humidityCount).toFixed(0);
        co2 = (co2 / co2Count).toFixed(0);
        return this.model.indoorAvg({
          temperature: temp,
          humidity: humidity,
          co2: co2
        });
      }
    };

    WeatherView.prototype.createChart = function(data) {
      var cWidth, canvas, chart, chartData, dsRain, dsTemperatureHigh, dsTemperatureLow, dsWind, labels, lineOptions;
      labels = _.pluck(data, "dateString");
      dsTemperatureHigh = {
        label: "Temp High",
        fillColor: "rgba(240, 65, 36, 0.3)",
        strokeColor: "rgb(240, 65, 36)",
        pointColor: "rgb(240, 65, 36)",
        pointStrokeColor: "rgb(250, 245, 240)",
        data: _.pluck(data, "temperatureHigh")
      };
      dsTemperatureLow = {
        label: "Temp Low",
        fillColor: "rgba(255, 255, 255, 0.9)",
        strokeColor: "rgb(230, 130, 60)",
        pointColor: "rgb(230, 130, 60)",
        pointStrokeColor: "rgb(250, 245, 240)",
        data: _.pluck(data, "temperatureLow")
      };
      dsWind = {
        label: "Wind",
        fillColor: "Transparent",
        strokeColor: "rgb(160, 170, 160)",
        pointColor: "rgb(160, 170, 160)",
        pointStrokeColor: "rgb(245, 245, 245)",
        data: _.pluck(data, "windSpeed")
      };
      dsRain = {
        label: "Precp.",
        fillColor: "Transparent",
        strokeColor: "rgb(80, 120, 170)",
        pointColor: "rgb(80, 120, 170)",
        pointStrokeColor: "rgb(240, 245, 250)",
        data: _.pluck(data, "precpChance")
      };
      lineOptions = {
        pointDotRadius: 3
      };
      canvas = $(".outside canvas");
      cWidth = canvas.parent().innerWidth() - 22;
      canvas.prop({
        width: cWidth
      });
      chartData = {
        labels: labels,
        datasets: [dsTemperatureHigh, dsTemperatureLow, dsWind, dsRain]
      };
      canvas = canvas.get(0).getContext("2d");
      return chart = new Chart(canvas).Line(chartData, lineOptions);
    };

    WeatherView.prototype.toggleChart = function() {
      var canvas, table;
      table = $(".outside .forecast");
      canvas = $(".outside .chart");
      if (table.is(":visible")) {
        table.hide();
        return canvas.show();
      } else {
        canvas.hide();
        return table.show();
      }
    };

    return WeatherView;

  })();

  window.weatherView = new WeatherView();

}).call(this);
