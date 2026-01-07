export async function register() {
  // Only run OpenTelemetry instrumentation in Node.js runtime
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./instrumentation.node");
  }
}
