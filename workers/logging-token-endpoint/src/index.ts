export interface Env {
  TOKEN_ENDPOINT: string;
}

// noinspection JSUnusedGlobalSymbols
export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    // Ensure TOKEN_ENDPOINT is configured
    if (!env.TOKEN_ENDPOINT) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: TOKEN_ENDPOINT is not set" }),
        { status: 500, headers: { "content-type": "application/json" } }
      );
    }

    if (request.method.toUpperCase() !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method Not Allowed. Use POST." }),
        { status: 405, headers: { "content-type": "application/json", "allow": "POST" } }
      );
    }

    // Clone and read the request body once so we can both log and forward it
    let bodyBuffer: ArrayBuffer | null = null;
    try {
      bodyBuffer = await request.arrayBuffer();
    } catch (e) {
      // If no body or unreadable, keep null
      bodyBuffer = null;
    }

    // Log incoming headers and body (as text, capped for safety)
    try {
      const headersObj: Record<string, string> = {};
      for (const [k, v] of request.headers.entries()) headersObj[k] = v;

      let bodyPreview: string | null = null;
      if (bodyBuffer) {
        // Convert to text for logging and truncate to avoid massive logs
        const text = new TextDecoder().decode(bodyBuffer);
        bodyPreview = text.length > 5000 ? text.slice(0, 5000) + "…[truncated]" : text;
      }

      console.log("[logging-token-endpoint] Incoming request:", {
        method: request.method,
        url: new URL(request.url).toString(),
        headers: headersObj,
        body: bodyPreview,
      });
    } catch (e) {
      // Best-effort logging; do not fail the request on logging errors
      console.warn("[logging-token-endpoint] Failed to log request", String(e));
    }

    // Prepare headers for forwarding
    const forwardHeaders = new Headers(request.headers);
    // Remove hop-by-hop or problematic headers
    forwardHeaders.delete("host");
    forwardHeaders.delete("content-length");

    // Forward the request to the configured token endpoint
    let upstreamResponse: Response;
    try {
      upstreamResponse = await fetch(env.TOKEN_ENDPOINT, {
        method: "POST",
        headers: forwardHeaders,
        body: bodyBuffer ? bodyBuffer : null,
        redirect: "manual",
      });
    } catch (err) {
      console.error("[logging-token-endpoint] Upstream fetch failed:", String(err));
      return new Response(
        JSON.stringify({ error: "Failed to reach TOKEN_ENDPOINT" }),
        { status: 502, headers: { "content-type": "application/json" } }
      );
    }

    // Optionally log upstream status and selected headers
    try {
      const resHeaders: Record<string, string> = {};
      for (const [k, v] of upstreamResponse.headers.entries()) resHeaders[k] = v;
      console.log("[logging-token-endpoint] Upstream response:", {
        status: upstreamResponse.status,
        statusText: upstreamResponse.statusText,
        headers: resHeaders,
      });
    } catch (e) {
      console.warn("[logging-token-endpoint] Failed to log upstream response", String(e));
    }

    // Return the upstream response as-is
    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      statusText: upstreamResponse.statusText,
      headers: upstreamResponse.headers,
    });
  },
} satisfies ExportedHandler<Env>;
