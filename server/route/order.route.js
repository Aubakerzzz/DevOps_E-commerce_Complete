import { Router } from 'express'
import auth from '../middleware/auth.js'
import { CashOnDeliveryOrderController, getOrderDetailsController, paymentController, webhookStripe, getAllOrdersController, updateOrderStatusController } from '../controllers/order.controller.js'
import { admin } from '../middleware/Admin.js'

const orderRouter = Router()

orderRouter.post("/cash-on-delivery",auth,CashOnDeliveryOrderController)
orderRouter.post('/checkout',auth,paymentController)
orderRouter.post('/webhook',webhookStripe)
orderRouter.get("/order-list",auth,getOrderDetailsController)
orderRouter.get('/all', auth, admin, getAllOrdersController)
orderRouter.patch('/update-status/:orderId', auth, admin, updateOrderStatusController)

export default orderRouter