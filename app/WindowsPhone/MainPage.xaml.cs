using System;
using Windows.UI.Xaml;
using Ayla.App.Common;
using Ayla.App.PortableRuntime.Services;

namespace Ayla.App
{
    public sealed partial class MainPage
    {
        private ObservableDictionary defaultViewModel = new ObservableDictionary();

        public MainPage()
        {
            InitializeComponent();
        }

        public ObservableDictionary DefaultViewModel
        {
            get { return defaultViewModel; }
        }

        private void Page_OnLoaded(object sender, RoutedEventArgs e)
        {
            WeatherService.GetCurrent();
        }
    }
}
