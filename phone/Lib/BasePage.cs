using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using AylaPhone.Resources;
using Microsoft.Phone.Controls;

namespace AylaPhone
{
	public class BasePage : PhoneApplicationPage
	{
        #region Properties

        protected Boolean BackCancel { get; set; }

        #endregion

		#region Base methods

		public BasePage()
		{
		    SupportedOrientations = SupportedPageOrientation.Portrait;
	        Orientation = PageOrientation.Portrait;
		}

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

            var topTitle = FindName("TopTitle");

            if (topTitle != null)
            {
                ((TextBlock)topTitle).Style = (Style)Application.Current.Resources["TopTitle"];
                ((TextBlock)topTitle).Text = AppResources.ApplicationTitle;
            }
        }

        protected override void OnBackKeyPress(CancelEventArgs e)
        {
            if (BackCancel)
            {
                e.Cancel = true;
                BackCancel = false;
            }
        }

	    protected void NavigateTo(String pageName)
	    {
            NavigationService.Navigate(new Uri("/" + pageName + "Page.xaml", UriKind.Relative));
	    }

		#endregion
	}
}