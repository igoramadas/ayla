using System;
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

        #endregion

        #region Dashboard

        private void HubLights_OnTap(object sender, GestureEventArgs e)
        {
            NavigateTo("HomeLights");
        }

        #endregion
    }
}