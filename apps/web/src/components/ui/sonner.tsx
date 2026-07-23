"use client";

import { useAtomValue } from "jotai";
import {
  CheckCircle,
  Info,
  Spinner,
  Warning,
  XOctagon,
} from "@phosphor-icons/react";
import { Toaster as Sonner, type ToasterProps } from "sonner";
import { themeAtom } from "@/stores/theme-atoms";

const Toaster = ({ ...props }: ToasterProps) => {
  const theme = useAtomValue(themeAtom);

  return (
    <Sonner
      theme={theme as ToasterProps["theme"]}
      className="toaster group"
      icons={{
        success: <CheckCircle className="size-4" />,
        info: <Info className="size-4" />,
        warning: <Warning className="size-4" />,
        error: <XOctagon className="size-4" />,
        loading: <Spinner className="size-4 animate-spin" />,
      }}
      style={
        {
          "--normal-bg": "var(--popover)",
          "--normal-text": "var(--popover-foreground)",
          "--normal-border": "var(--border)",
          "--border-radius": "var(--radius)",
        } as React.CSSProperties
      }
      toastOptions={{
        classNames: {
          toast: "cn-toast",
        },
      }}
      {...props}
    />
  );
};

export { Toaster };
