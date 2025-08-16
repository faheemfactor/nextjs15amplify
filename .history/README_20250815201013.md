# Next.js 15 Simple App

A simple Next.js 15 TypeScript application with a single API endpoint and page.

## Features

- Next.js 15 with TypeScript
- Standalone build configuration
- Simple API endpoint (`/api/data`)
- Modern React with hooks
- Responsive design

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Run the development server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production (standalone)
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## API Endpoints

- `GET /api/data` - Returns a JSON object with message, timestamp, version, and environment

## Build for Production

The app is configured for standalone build:

```bash
npm run build
```

This creates a standalone build in the `.next/standalone` directory that can be deployed to various platforms.

## Deployment

This app is configured for deployment to AWS Amplify and other platforms that support Next.js standalone builds.

## Project Structure

```
├── app/
│   ├── api/data/route.ts    # API endpoint
│   ├── globals.css          # Global styles
│   ├── layout.tsx           # Root layout
│   └── page.tsx             # Main page
├── next.config.js           # Next.js configuration
├── package.json             # Dependencies and scripts
├── tsconfig.json            # TypeScript configuration
└── README.md               # This file
```
