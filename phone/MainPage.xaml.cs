using System;
using System.Windows;
using System.Windows.Input;

namespace AylaPhone
{
	public partial class MainPage
    {
        #region Main methods

        public MainPage()
		{
			InitializeComponent();
        }

        private void Page_Loaded(Object sender, RoutedEventArgs e)
        {
            HomeService.GetLights();
        }

        #endregion

        #region Dashboard

        private void HubLights_OnTap(object sender, GestureEventArgs e)
        {
            NavigateTo("HomeLights");
        }

        #endregion
    }
}