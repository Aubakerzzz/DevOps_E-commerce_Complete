import React, { useEffect, useState } from 'react';
import Axios from '../utils/Axios';
import SummaryApi from '../common/SummaryApi';
import Loading from '../components/Loading';
import toast from 'react-hot-toast';
import isAdmin from '../utils/isAdmin';
import { useSelector } from 'react-redux';

const statusOptions = ['Pending', 'Shipped', 'Delivered', 'Rejected'];

const AllOrdersAdmin = () => {
  const user = useSelector(state => state.user);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isAdmin(user.role)) {
      fetchOrders();
    }
    // eslint-disable-next-line
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await Axios({
        ...SummaryApi.getAllOrders,
        withCredentials: true,
      });
      setOrders(res.data.data || []);
    } catch (err) {
      toast.error('Failed to fetch orders');
    }
    setLoading(false);
  };

  const handleStatusChange = async (orderId, status) => {
    try {
      await Axios({
        ...SummaryApi.updateOrderStatus(orderId),
        data: { status },
        withCredentials: true,
      });
      toast.success('Order status updated');
      fetchOrders();
    } catch (err) {
      toast.error('Failed to update status');
    }
  };

  if (!isAdmin(user.role)) {
    return <div className="p-4 text-red-600">Permission Denied</div>;
  }

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-4">All Orders</h2>
      {loading ? (
        <Loading />
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full border">
            <thead>
              <tr className="bg-gray-100">
                <th className="p-2 border">Order ID</th>
                <th className="p-2 border">User</th>
                <th className="p-2 border">Product</th>
                <th className="p-2 border">Amount</th>
                <th className="p-2 border">Status</th>
                <th className="p-2 border">Change Status</th>
                <th className="p-2 border">Date</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(order => (
                <tr key={order._id}>
                  <td className="p-2 border">{order.orderId}</td>
                  <td className="p-2 border">{order.userId?.name || order.userId?.email || 'N/A'}</td>
                  <td className="p-2 border">{order.product_details?.name}</td>
                  <td className="p-2 border">₹{order.totalAmt}</td>
                  <td className="p-2 border font-semibold">{order.status}</td>
                  <td className="p-2 border">
                    <select
                      value={order.status}
                      onChange={e => handleStatusChange(order._id, e.target.value)}
                      className="border rounded px-2 py-1"
                    >
                      {statusOptions.map(opt => (
                        <option key={opt} value={opt}>{opt}</option>
                      ))}
                    </select>
                  </td>
                  <td className="p-2 border">{new Date(order.createdAt).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default AllOrdersAdmin; 