import { Spinner } from "@phosphor-icons/react/ssr";

export default function Loading() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <Spinner className="size-12 animate-spin text-primary" />
      <p className="mt-4 text-muted-foreground">Loading...</p>
    </main>
  );
}
