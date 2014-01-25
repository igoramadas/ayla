using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;

namespace AylaPhone
{
	public class BasePage : PhoneApplicationPage
	{
		#region "Base methods"

		public BasePage()
		{
		    SupportedOrientations = SupportedPageOrientation.Portrait;
	        Orientation = PageOrientation.Portrait;
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
		}

		#endregion
	}
}