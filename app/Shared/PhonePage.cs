using System;
using Windows.ApplicationModel.Resources;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;
using Ayla.App.Common;

namespace Ayla.App
{
    public class PhonePage : Page
    {
        #region Properties

        protected NavigationHelper NavHelper { get; set; }

        #endregion

        #region Base methods

        public PhonePage()
        {
            NavHelper = new NavigationHelper(this);
        }

        private async void NavHelper_LoadState(Object sender, LoadStateEventArgs e)
        {
            
        }

        private async void NavHelper_SaveState(Object sender, LoadStateEventArgs e)
        {
            
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            NavHelper.OnNavigatedTo(e);

            var appResources = new ResourceLoader();
            var layoutRoot = FindName("LayoutRoot") as Grid;
            var topTitle = layoutRoot.FindName("TopTitle");

            if (topTitle != null)
            {
                ((TextBlock)topTitle).Style = (Style)Application.Current.Resources["TopTitle"];
                ((TextBlock)topTitle).Text = appResources.GetString("AppTitle");
            }
        }

        protected override void OnNavigatedFrom(NavigationEventArgs e)
        {
            NavHelper.OnNavigatedFrom(e);
        }

        #endregion
    }
}