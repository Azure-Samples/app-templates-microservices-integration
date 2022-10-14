using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace RedDog.VirtualCustomer
{
    public static class HttpClientExtensions
    {
        /// <summary>
        /// Serialize the HTTP content to a JSON string as an asynchronous operation
        /// then deserializes the JSON to the specified .NET type.
        /// </summary>
        /// <typeparam name="T">The type of object to be deserialized</typeparam>
        /// <param name="content">The HTTP content</param>
        /// <returns></returns>
        public static async Task<T> GetAsync<T>(this HttpClient client, string url)
        {
            if (client == null)
                throw new ArgumentNullException(nameof(client));

            var response = await client.GetAsync(url).ConfigureAwait(false);
            var result = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
            return await response.Content.ReadAsJsonAsync<T>().ConfigureAwait(false);
        }
    }
}
