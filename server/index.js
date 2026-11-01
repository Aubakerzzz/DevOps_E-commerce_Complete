import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import cookieParser from 'cookie-parser'
import morgan from 'morgan'
import helmet from 'helmet'

import connectDB from './config/connectDB.js'
import userRouter from './route/user.route.js'
import categoryRouter from './route/category.route.js'
import uploadRouter from './route/upload.router.js'
import subCategoryRouter from './route/subCategory.route.js'
import productRouter from './route/product.route.js'
import cartRouter from './route/cart.route.js'
import addressRouter from './route/address.route.js'
import orderRouter from './route/order.route.js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 5000

// CORS: allow your local Docker frontend and deployed frontend
const allowedOrigins = [
    'http://localhost:8080',
    'http://localhost:5173',
    process.env.FRONTEND_URL
].filter(Boolean)

app.use(cors({
    credentials: true,
    origin: (origin, callback) => {
        // Allow requests without an Origin header, such as server-to-server calls
        if (!origin || allowedOrigins.includes(origin)) {
            return callback(null, true)
        }

        return callback(new Error(`CORS blocked origin: ${origin}`))
    }
}))

app.use(express.json())
app.use(cookieParser())
app.use(morgan('dev'))

app.use(helmet({
    crossOriginResourcePolicy: false
}))

// Health-check / root route
app.get('/', (request, response) => {
    response.json({
        message: `Server is running on port ${PORT}`
    })
})

// Existing API routes
app.use('/api/user', userRouter)
app.use('/api/category', categoryRouter)
app.use('/api/file', uploadRouter)
app.use('/api/subcategory', subCategoryRouter)
app.use('/api/product', productRouter)
app.use('/api/cart', cartRouter)
app.use('/api/address', addressRouter)
app.use('/api/order', orderRouter)

// Connect to MongoDB before starting the server
async function startServer() {
    try {
        await connectDB()

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server is running on port ${PORT}`)
        })
    } catch (error) {
        console.error('Failed to start server:', error)
        process.exit(1)
    }
}

startServer()
