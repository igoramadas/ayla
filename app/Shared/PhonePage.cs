using System;
using Windows.ApplicationModel.Resources;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace Ayla.App
{
    public class PhonePage : Page
	{
        #region Properties

        protected Boolean BackCancel { get; set; }

        #endregion

		#region Base methods

        public PhonePage()
		{
		}

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            var appResources = new ResourceLoader();

            base.OnNavigatedTo(e);

            var topTitle = FindName("TopTitle");

            if (topTitle != null)
            {
                ((TextBlock)topTitle).Style = (Style)Application.Current.Resources["TopTitle"];
                ((TextBlock) topTitle).Text = appResources.GetString("AppTitle");
            }
        }

		#endregion
	}
}