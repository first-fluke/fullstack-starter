import { defineConfig } from "orval";

export default defineConfig({
  api: {
    input: "../api/openapi.json",
    output: {
      target: "./src/lib/api/generated.ts",
      schemas: "./src/lib/api/model",
      client: "react-query",
      httpClient: "axios",
      mode: "tags-split",
      namingConvention: "kebab-case",
      clean: true,
      override: {
        mutator: {
          name: "useCustomInstance",
          path: "./src/hooks/use-custom-instance.ts",
        },
        query: {
          useInfinite: true,
          useSuspenseQuery: true,
        },
      },
    },
  },
  zod: {
    input: "../api/openapi.json",
    output: {
      target: "./src/lib/api/zod",
      client: "zod",
      mode: "tags-split",
      namingConvention: "kebab-case",
      fileExtension: ".zod.ts",
      clean: true,
    },
  },
});
