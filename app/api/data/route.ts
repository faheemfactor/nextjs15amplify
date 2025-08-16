import { NextResponse } from "next/server";

export async function GET() {
  const data = {
    message: "Hello from Next.js 15 API!",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    environment: process.env.NODE_ENV || "development",
  };

  return NextResponse.json(data);
}
