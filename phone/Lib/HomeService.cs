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

        #region Lights

        public static Task<List<Light>> GetLights()
        {
            var tcs = new TaskCompletionSource<List<Light>>();
            var web = new WebClient();

            web.DownloadStringCompleted += (sender, e) =>
            {
                if (e.Error != null) tcs.TrySetException(e.Error);
                else if (e.Cancelled) tcs.TrySetCanceled();
                else tcs.TrySetResult(JsonConvert.DeserializeObject<List<Light>>(e.Result));
            };

            web.DownloadStringAsync(new Uri(Settings.HomeUrl));
            return tcs.Task;
        }

        #endregion
    }
}