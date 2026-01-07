import type { Locale } from "next-intl";
import { setRequestLocale } from "next-intl/server";

interface NotFoundPageProps {
  params: Promise<{ locale: string }>;
}

export default async function NotFoundPage({ params }: NotFoundPageProps) {
  const { locale } = await params;
  setRequestLocale(locale as Locale);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-6xl font-bold">404</h1>
      <p className="mt-4 text-muted-foreground">Page not found</p>
    </main>
  );
}
