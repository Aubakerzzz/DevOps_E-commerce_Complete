Here is the `README.md` for the **client** folder. It documents the React frontend architecture, the specific tech stack derived from your `package.json`, the folder structure shown in your screenshot, and how to run it both locally and via Docker.

Save this in `docs/client/README.md`.

```markdown
# Leyo — Client (React Frontend)

This folder contains the **React + Vite** single-page application (SPA) for Leyo. It handles the user interface, routing, state management, and API communication with the Express backend.

---

## 1. Technology Stack

The project uses a modern frontend stack focused on performance and developer experience:

| Category | Technology | Purpose |
|---|---|---|
| **Framework** | React 18 | UI library |
| **Build Tool** | Vite 5 | Fast bundler and dev server |
| **Styling** | Tailwind CSS 3 | Utility-first CSS framework |
| **State Mgt** | Redux Toolkit | Global state (user, cart, products) |
| **Routing** | React Router v6 | Client-side navigation |
| **HTTP Client** | Axios | API requests |
| **Forms** | React Hook Form | Form state and validation |
| **UI/UX** | React Hot Toast, SweetAlert2 | Notifications and modals |
| **Icons** | React Icons | SVG icon library |
| **Tables** | TanStack Table | Headless table logic |
| **Payments** | Stripe.js | Payment processing |
| **Linting** | ESLint 9 | Code quality |

---

## 2. Folder Structure

Based on the project root, the source code is organized as follows:

```text
client/
├── src/
│   ├── assets/         # Images, fonts, static files
│   ├── common/         # API endpoint definitions (SummaryApi.js)
│   ├── components/     # Reusable UI components (Header, Footer, Cards)
│   ├── hooks/          # Custom React hooks
│   ├── layouts/        # Page layout wrappers
│   ├── pages/          # Route-level components (Home, Cart, Admin)
│   ├── provider/       # Context providers (GlobalProvider)
│   ├── route/          # React Router configuration (index.js)
│   ├── store/          # Redux slices and store configuration
│   ├── utils/          # Helper functions (Axios instance, fetchUserDetails)
│   ├── App.jsx         # Root component & global data fetching
│   ├── App.css         # App-specific styles
│   ├── index.css       # Global Tailwind imports & base styles
│   └── main.jsx        # React entry point (Provider & Router setup)
├── .eslintrc.js        # ESLint configuration
├── index.html          # Vite HTML entry point
├── package.json        # Dependencies and scripts
├── postcss.config.js   # PostCSS config for Tailwind
├── tailwind.config.js  # Tailwind theme and content paths
└── vite.config.js      # Vite build configuration
```

---

## 3. Core Architecture

### Global State (Redux)
The app uses `@reduxjs/toolkit`. The store is configured in `src/store/store.js`. Key slices include:
- `userSlice`: Stores logged-in user details.
- `productSlice`: Stores categories, subcategories, and loading states.
- `cartProduct`: Manages shopping cart state.

### Routing
Routing is handled by `react-router-dom` in `src/route/index.js`. The `main.jsx` file wraps the app in a `<RouterProvider>` and a Redux `<Provider>`.

### API Communication
- **Axios Instance**: Configured in `src/utils/Axios.js` (likely includes base URL and interceptors for tokens).
- **Endpoints**: Centralized in `src/common/SummaryApi.js`.
- **Global Fetching**: `App.jsx` uses `useEffect` to fetch user details, categories, and subcategories on initial load.

### Styling
- **Tailwind CSS**: Configured in `tailwind.config.js`. Custom colors are defined (e.g., `primary-200`, `secondary-100`).
- **Global CSS**: `index.css` imports the "Poppins" font and sets base body styles.
- **App CSS**: `App.css` also imports Tailwind directives and the font.

---

## 4. Environment Variables

The frontend requires the backend API URL to be configured via Vite environment variables. Create a `.env` file in the root of the `client` folder:

```env
VITE_API_URL=http://localhost:5000
```

> **Important:** Vite only exposes variables prefixed with `VITE_` to the browser.

---

## 5. Running Locally (Development)

### Prerequisites
- Node.js v18+ (v20+ recommended)
- npm or yarn

### Steps
1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the Vite development server:
   ```bash
   npm run dev
   ```
   The app will be available at `http://localhost:5173` (default Vite port).

3. To run the production build locally:
   ```bash
   npm run build
   npm run preview
   ```

---

## 6. Linting

To check for code quality issues using ESLint 9 (flat config):

```bash
npm run lint
```

---

## 7. Docker Deployment

The client is designed to be built into a static Docker image and served via Nginx.

### Dockerfile (Example)
```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Pass the API URL at build time
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Serve stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Building the Image
```bash
docker build -t leyo-client:local --build-arg VITE_API_URL=http://localhost:5000 .
```

### Running the Container
```bash
docker run -p 8080:80 leyo-client:local
```
Access the app at `http://localhost:8080`.

---

## 8. Deployment Context

This client is deployed as part of the full Leyo stack. Depending on the environment:

1. **Docker Compose (VM)**: Built via the `docker-compose.yaml` in the project root and deployed to AWS/Azure/IBM VMs.
2. **Kubernetes (Helm)**: Deployed via the `helm` chart as a Deployment with a NodePort or Ingress.
3. **GitHub Actions**: Built and pushed automatically on pushes to the `main` branch.

*Refer to the root `README.md` and `docs/HELM/README.md` for deployment workflows.*
```

### Notes on accuracy:
- I mapped the files shown in your screenshot directly into the "Folder Structure" section.
- I explicitly mentioned the custom Tailwind colors (`primary-200`, etc.) found in your `tailwind.config.js`.
- I noted the specific state management setup (Redux) and global fetching logic found in `App.jsx`.
- The Dockerfile is provided as a standard example for Vite/React, as the actual Dockerfile wasn't included in the file list.