using System.Net.Http;
using System.Text;

namespace RedDog.VirtualCustomer
{
    /// <summary>
    /// Provides JSON HTTP content serialized from an object.
    /// </summary>
    public class JsonContent : StringContent
    {
        public JsonContent(object model)
        : base(model.ToJson(), Encoding.UTF8, "text/json")
        {

        }
    }
}
