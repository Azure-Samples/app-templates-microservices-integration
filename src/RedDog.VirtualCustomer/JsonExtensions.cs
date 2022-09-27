using System;
using System.Collections;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace RedDog.VirtualCustomer
{
    public static class JsonExtensions
    {
        /// <summary>
        /// Returns the JSON representation of an object
        /// </summary>
        /// <param name="entity"></param>
        /// <returns></returns>
        public static string ToJson(this object entity)
        {
            return JsonConvert.SerializeObject(entity, new IsoDateTimeConverter());
        }

        /// <summary>
        /// Deserializes the JSON to the specified .NET type.
        /// </summary>
        /// <typeparam name="T">The type of the object to deserialize to.</typeparam>
        /// <param name="json">The JSON to deserialize.</param>
        /// <returns>The deserialized object from the Json string.</returns>
        public static T FromJson<T>(this string json)
        {
            return JsonConvert.DeserializeObject<T>(json);
        }
    }
}
