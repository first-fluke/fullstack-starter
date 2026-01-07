import { useCallback } from "react";
import { apiClient } from "@/lib/api-client";

export const useCustomInstance = <T>() => {
  return useCallback(
    async (config: {
      url: string;
      method: string;
      params?: object;
      data?: unknown;
      signal?: AbortSignal;
    }): Promise<T> => {
      const { data } = await apiClient.request<T>(config);
      return data;
    },
    []
  );
};
