using System;
using System.Dynamic;
using System.IO.IsolatedStorage;

namespace AylaPhone
{
    public class Settings
    {
        #region Properties

        public static String HomeUrl
        {
            get { return Get("HomeUrl", "https://home.ayla.pw/"); }
            set { Set("HomeUrl", value); }
        }

        #endregion

        #region Implementation

        static IsolatedStorageSettings data;

        // Settings constructor.
        public Settings()
        {
            data = IsolatedStorageSettings.ApplicationSettings;
        }

        // Save settings to isolated storage.
        public void Save()
        {
            data.Save();
        }

        // Set a setting value.
        public static Boolean Set(String key, Object value)
        {
            Boolean valueChanged = false;

            // If the key exists, check if value has changed and store new value.
            if (data.Contains(key))
            {
                if (data[key] != value)
                {
                    data[key] = value;
                    valueChanged = true;
                }
            }
            // Otherwise create the new key.
            else
            {
                data.Add(key, value);
                valueChanged = true;
            }

            return valueChanged;
        }

        // Get a setting or its default value.
        public static T Get<T>(String key, T defaultValue)
        {
            T value;

            // If the key exists, retrieve the value, otherwise use default.
            if (data.Contains(key))
            {
                value = (T)data[key];
            }
            else
            {
                value = defaultValue;
            }

            return value;
        }

        #endregion
    }
}