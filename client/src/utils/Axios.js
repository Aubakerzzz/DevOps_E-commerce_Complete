// client/src/utils/Axios.js
import axios from "axios";

const Axios = axios.create({
    baseURL: "http://localhost:5000", // Ensure this is correct
    withCredentials: true // 🔥 THIS IS THE CRITICAL FIX
});

export default Axios;