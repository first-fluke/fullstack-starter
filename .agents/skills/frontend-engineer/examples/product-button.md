# Product Button Pattern

Wrapper pattern for `shadcn/ui` components.
**Key Rule**: Do NOT modify `components/ui/button.tsx`. Create a wrapper for custom logic (loading state, specific branding).

## `src/components/common/product-button.tsx`

```tsx
import { Button, type ButtonProps } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { Loader2 } from "lucide-react";

interface ProductButtonProps extends ButtonProps {
  isLoading?: boolean;
}

export function ProductButton({
  children,
  className,
  isLoading,
  disabled,
  ...props
}: ProductButtonProps) {
  return (
    <Button
      disabled={disabled || isLoading}
      className={cn("font-semibold", className)}
      {...props}
    >
      {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
      {children}
    </Button>
  );
}
```
