using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RedDog.AccountingModel;

namespace RedDog.AccountingService.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProbesController : ControllerBase
    {
        private static bool isReady;
        private string DaprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
        private ILogger<ProbesController> _logger;
        private HttpClient _httpClient;

        public ProbesController(ILogger<ProbesController> logger, IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
        }

        [HttpGet("ready")]
        public async Task<IActionResult> IsReady([FromServices] AccountingContext dbContext)
        {
            if(!isReady)
            {
                try
                {
                    if(await dbContext.Orders.CountAsync() >= 0 && 
                       await dbContext.OrderItems.CountAsync() >= 0 &&
                       await dbContext.Customers.CountAsync() >= 0)
                    {
                        isReady = true;
                    }
                }
                catch(Exception e)
                {
                    _logger.LogWarning(e, "Readiness probe failure.");
                }

                return new StatusCodeResult(503);
            }

            return Ok();
        }

        [HttpGet("healthz")]
        public async Task<IActionResult> IsHealthy()
        {
            // Ensure dapr sidecar is running and healthy. If not, fail the health check and have the pod restarted.
            // This should prevent the case where the application container is running before dapr is installed in
            // the case of a gitops deploy.
            var response = await _httpClient.GetAsync($"http://localhost:{DaprHttpPort}/v1.0/healthz");
            return new StatusCodeResult((int)response.StatusCode);
        }
    }
}