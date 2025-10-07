import type { Metadata } from "next";
import { Inter, Merriweather, JetBrains_Mono } from "next/font/google";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { DomainThemeProvider } from "@/components/providers/domain-theme-provider";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

// UI font - clean, modern, excellent for interfaces
const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

// Reading font - elegant, comfortable for long-form content
const merriweather = Merriweather({
  variable: "--font-merriweather",
  weight: ["300", "400", "700"],
  subsets: ["latin"],
  display: "swap",
});

// Code font - monospace for technical content
const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "The Builder Platform",
  description: "Domain-agnostic expert content creation with knowledge compounding",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${inter.variable} ${merriweather.variable} ${jetbrainsMono.variable} font-sans antialiased`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          <DomainThemeProvider>
            {children}
            <Toaster />
          </DomainThemeProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
