Here is the `README.md` for the **server** (backend) folder. It documents the Node.js/Express architecture, the specific tech stack, the folder structure shown in your screenshots, required environment variables, and how to run it.

Save this in `docs/server/README.md`.

```markdown
# Leyo — Server (Express Backend)

This folder contains the **Node.js/Express** REST API that powers the Leyo application. It handles user authentication, product/category management, cart operations, order processing, and integrations with third-party services like Stripe and Cloudinary.

---

## 1. Technology Stack

Derived from `package.json`, the backend uses:

| Category | Technology | Purpose |
|---|---|---|
| **Runtime** | Node.js | JavaScript runtime |
| **Framework** | Express 4 | HTTP server and routing |
| **Database** | MongoDB & Mongoose | NoSQL database and ODM |
| **Authentication** | JWT & bcryptjs | Token generation and password hashing |
| **File Uploads** | Multer | Handling `multipart/form-data` |
| **Storage** | Cloudinary | Cloud image hosting |
| **Payments** | Stripe | Payment processing |
| **Emails** | Resend | Transactional emails (OTP, password reset) |
| **Security** | Helmet, CORS | HTTP headers and cross-origin rules |
| **Logging** | Morgan | HTTP request logger |
| **Dev Tool** | Nodemon | Auto-restart during development |

---

## 2. Folder Structure

Based on the project root, the source code is organized using the **MVC (Model-View-Controller)** pattern:

```text
server/
├── config/             # Configuration and third-party service setups
│   ├── cloudinary.js   # Cloudinary SDK configuration
│   ├── connectDB.js    # Mongoose connection logic
│   ├── sendEmail.js    # Resend email client setup
│   └── stripe.js       # Stripe SDK configuration
├── controllers/        # Request handlers (business logic)
│   ├── address.controller.js
│   ├── cart.controller.js
│   ├── category.controller.js
│   ├── order.controller.js
│   ├── product.controller.js
│   ├── subCategory.controller.js
│   ├── uploadImage.controller.js
│   └── user.controller.js
├── middleware/         # Express middlewares
│   ├── Admin.js        # Checks if the user has admin privileges
│   ├── auth.js         # Verifies JWT access tokens
│   └── multer.js       # Configures file upload handling
├── models/             # Mongoose Schemas
│   ├── address.model.js
│   ├── cartproduct.model.js
│   ├── category.model.js
│   ├── order.model.js
│   ├── product.model.js
│   ├── subCategory.model.js
│   └── user.model.js
├── route/              # Express Routers (API endpoints)
│   ├── address.route.js
│   ├── cart.route.js
│   ├── category.route.js
│   ├── order.route.js
│   ├── product.route.js
│   ├── subCategory.route.js
│   ├── upload.router.js
│   └── user.route.js
├── utils/              # Helper functions
│   ├── forgotPasswordTemplate.js
│   ├── generatedAccessToken.js
│   ├── generatedOtp.js
│   ├── generatedRefreshToken.js
│   ├── uploadImageClodinary.js
│   └── verifyEmailTemplate.js
├── .env                # Environment variables (not committed)
├── index.js            # Application entry point
├── package.json        # Dependencies and scripts
└── vercel.json         # Vercel deployment configuration
```

---

## 3. Core Architecture

### The Entry Point (`index.js`)
The `index.js` file initializes the Express app, configures middleware, mounts the routers, and connects to MongoDB before starting the server.
- **CORS**: Configured to allow requests from `http://localhost:8080`, `http://localhost:5173`, and the `process.env.FRONTEND_URL`. It supports credentials (cookies).
- **Security**: `helmet` is used with `crossOriginResourcePolicy: false` to allow images to be served cross-origin.
- **Global Middleware**: `express.json()`, `cookieParser()`, and `morgan('dev')`.
- **Health Check**: A `GET /` route returns a simple JSON message.

### Routing & Controllers
The app mounts specific routers to API paths:
- `/api/user` → `user.route.js`
- `/api/category` → `category.route.js`
- `/api/subcategory` → `subCategory.route.js`
- `/api/product` → `product.route.js`
- `/api/cart` → `cart.route.js`
- `/api/address` → `address.route.js`
- `/api/order` → `order.route.js`
- `/api/file` → `upload.router.js`

Controllers handle the incoming requests, interact with the database via Mongoose models, and send responses.

### Middleware
- **`auth.js`**: Protects routes by verifying the JWT (likely from an HTTP-only cookie or the Authorization header).
- **`Admin.js`**: Ensures the authenticated user has the `ADMIN` role before allowing access to certain endpoints.
- **`multer.js`**: Configures `multer` to handle file uploads in memory before passing them to Cloudinary.

---

## 4. Environment Variables

Create a `.env` file in the root of the `server` folder. The following variables are required based on the codebase:

```env
# Server
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:5173

# Database
MONGODB_URI=mongodb://localhost:27017/leyo

# JWT Secrets
SECRET_KEY_ACCESS_TOKEN=your_super_secret_access_key
SECRET_KEY_REFRESH_TOKEN=your_super_secret_refresh_key

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Resend (Email)
RESEND_API=re_...
```

---

## 5. Running Locally (Development)

### Prerequisites
- Node.js v18+ (v20+ recommended)
- A running MongoDB instance (local or Atlas)

### Steps
1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the development server (uses `nodemon` for hot-reloading):
   ```bash
   npm run dev
   ```
   The API will be available at `http://localhost:5000`.

3. To run the production build:
   ```bash
   npm start
   ```

---

## 6. Deployment

### Docker (Standard)
The server is designed to be containerized. A standard `Dockerfile` for this Node.js app:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 5000
CMD ["node", "index.js"]
```

