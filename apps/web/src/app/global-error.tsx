"use client";

interface GlobalErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function GlobalError({ error, reset }: GlobalErrorProps) {
  return (
    <html lang="en">
      <body>
        <main className="flex min-h-screen flex-col items-center justify-center p-24">
          <h1 className="text-4xl font-bold text-red-600">Something went wrong!</h1>
          <p className="mt-4 text-gray-600">
            {error.digest && <span>Error ID: {error.digest}</span>}
          </p>
          <button
            type="button"
            onClick={reset}
            className="mt-8 rounded-md bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700"
          >
            Try again
          </button>
        </main>
      </body>
    </html>
  );
}
