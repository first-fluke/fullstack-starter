import type { Locale } from "next-intl";
import { setRequestLocale } from "next-intl/server";

interface HomePageProps {
  params: Promise<{ locale: string }>;
}

export default async function HomePage({ params }: HomePageProps) {
  const { locale } = await params;
  setRequestLocale(locale as Locale);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">Fullstack Starter</h1>
      <p className="mt-4 text-muted-foreground">
        Modern monorepo template with Next.js, FastAPI, and Flutter
      </p>
    </main>
  );
}
