using System;
using System.Collections.Generic;
using System.Net;
using System.ServiceModel;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AylaPhone
{
    public class HomeService
    {
        #region Properties

        #endregion

        #region Base Implementation

        // Base method to get and post data to the home server.
        private static Task<String> MakeRequest(WebClient web, String path, JObject data = null)
        {
            var tcs = new TaskCompletionSource<String>();
            web.Headers["Content-Type"] = "application/json";

            web.DownloadStringCompleted += (sender, e) =>
            {
                if (e.Error != null) tcs.TrySetException(e.Error);
                else if (e.Cancelled) tcs.TrySetCanceled();
                else tcs.TrySetResult(e.Result);
            };

            if (data != null && data.HasValues)
            {
                web.DownloadStringAsync(new Uri(Settings.HomeUrl + path));
            }
            else
            {
                web.UploadStringAsync(new Uri(Settings.HomeUrl + path), "POST", JsonConvert.SerializeObject(data));
            }
            
            return tcs.Task;
        }

        #endregion

        #region Lights

        // Get list of lights from the home server.
        public async static Task<JObject> GetLights()
        {
            var web = new WebClient();
            var task = await MakeRequest(web, "lights");

            return JsonConvert.DeserializeObject<JObject>(task);
        }

        // Set the state of the specified light.
        public async static Task<JObject> SetLightState(String lightId)
        {
            var web = new WebClient();
            var task = await MakeRequest(web, "lights/state");

            return JsonConvert.DeserializeObject<JObject>(task);
        }

        #endregion

        #region Weather

        // Get current weahter info for indoors and outdoors.
        public async static Task<JObject> GetWeather()
        {
            var web = new WebClient();
            var task = await MakeRequest(web, "weather");

            return JsonConvert.DeserializeObject<JObject>(task);
        }
        
        #endregion
    }
}