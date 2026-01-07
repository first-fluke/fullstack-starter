import { TraceExporter } from "@google-cloud/opentelemetry-cloud-trace-exporter";
import { FetchInstrumentation } from "@opentelemetry/instrumentation-fetch";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { TraceIdRatioBasedSampler } from "@opentelemetry/sdk-trace-base";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";

const serviceName = process.env.OTEL_SERVICE_NAME || "web";
const sampleRate = Number.parseFloat(process.env.OTEL_SAMPLE_RATE || "0.1");

const sdk = new NodeSDK({
  instrumentations: [new HttpInstrumentation(), new FetchInstrumentation()],

  resource: resourceFromAttributes({
    [ATTR_SERVICE_NAME]: serviceName,
  }),

  sampler: new TraceIdRatioBasedSampler(sampleRate),

  traceExporter: new TraceExporter(),
});

sdk.start();
