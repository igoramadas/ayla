using System;
using System.Collections.Generic;
using System.Net;
using System.ServiceModel;
using System.Threading.Tasks;
using AylaPhone.Entities;
using Newtonsoft.Json;

namespace AylaPhone
{
    public class HomeService
    {
        #region Properties

        #endregion

        #region Base Implementation

        // Base method to get and post data to the home server.
        private static Task<String> MakeRequest(WebClient web, String path, String data = "")
        {
            var tcs = new TaskCompletionSource<String>();
            web.Headers["Content-Type"] = "application/json";

            web.DownloadStringCompleted += (sender, e) =>
            {
                if (e.Error != null) tcs.TrySetException(e.Error);
                else if (e.Cancelled) tcs.TrySetCanceled();
                else tcs.TrySetResult(e.Result);
            };

            if (data != "")
            {
                web.DownloadStringAsync(new Uri(Settings.HomeUrl + path));
            }
            else
            {
                web.UploadStringAsync(new Uri(Settings.HomeUrl + path), "POST", data);
            }
            
            return tcs.Task;
        }

        #endregion

        #region Lights

        // Get list of lights from the home server.
        public async static Task<List<Light>> GetLights()
        {
            var web = new WebClient();
            var task = await MakeRequest(web, "lights");

            return JsonConvert.DeserializeObject<List<Light>>(task);
        }

        #endregion
    }
}