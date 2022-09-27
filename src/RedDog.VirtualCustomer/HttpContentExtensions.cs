using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace RedDog.VirtualCustomer
{
    public static class HttpContentExtensions
    {
        /// <summary>
        /// Serialize the HTTP content to a JSON string as an asynchronous operation
        /// then deserializes the JSON to the specified .NET type.
        /// </summary>
        /// <typeparam name="T">The type of object to be deserialized</typeparam>
        /// <param name="content">The HTTP content</param>
        /// <returns></returns>
        public static async Task<T> ReadAsJsonAsync<T>(this HttpContent content)
        {
            if (content == null)
                throw new ArgumentNullException(nameof(content));

            var responseString = await content.ReadAsStringAsync().ConfigureAwait(false);
            return responseString.FromJson<T>();
        }
    }
}
