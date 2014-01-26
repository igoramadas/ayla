using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace AylaPhone
{
    public partial class HomeLightsPage
    {
        #region Main methods

        public HomeLightsPage()
        {
            InitializeComponent();
        }

        private void Page_Loaded(Object sender, RoutedEventArgs e)
        {
            var lights = HomeService.GetLights();
        }

        #endregion

        #region Lights control

        #endregion
    }
}