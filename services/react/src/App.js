import './App.css';
import * as md5 from 'js-md5'
import {useEffect, useState} from "react";
import axios from "axios";
import Form from "./Components/Form";
import {toast, ToastContainer} from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const baseURL = "http://localhost:6006/api/v1/customers";

function App() {
    const [customers, setCustomers] = useState([]);
    const [isSubmitted, setIsSubmitted] = useState(false)
    function handleSubmission (){setIsSubmitted(!isSubmitted)}

    const handleDelete = (id) => {
        // eslint-disable-next-line no-restricted-globals
        if (confirm('Are you sure delete the customer ?')) {
            axios.delete(`${baseURL}/${id}`)
                .then((response) => {
                    toast("Successfully delete the customer info", {type: "success"})
                    setCustomers(customers.filter((customer) => customer.id != id))
                })
                .catch((error) => {
                    toast("Something went wrong", {type: "error"})
                })
        }
    }
    useEffect(() => {
        axios.get(baseURL)
            .then((response) => {
                toast(`Customer collection get from ${response.data.cached ? "redis" : "database"}`, {type: "info"})
                setCustomers(response.data.data)
            })
    }, [isSubmitted])


    return (
        <div className="bg-white">
            <ToastContainer
                position="top-right"
                autoClose={2000}
                hideProgressBar={false}
                newestOnTop={true}
                closeOnClick
                pauseOnFocusLoss
                draggable
                pauseOnHover
                theme="light">
                </ToastContainer>
            <div className="relative isolate px-6 pt-1 lg:px-8">
                <div className="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80"
                     aria-hidden="true">
                </div>
                <div className="mx-auto max-w-2xl py-2 sm:py-48 lg:py-8">
                    <div className="text-center">
                        <h1 className="text-2xl font-bold tracking-tight text-gray-900 sm:text-2xl">Customer Info</h1>
                    </div>
                    <Form handleSubmission={handleSubmission}/>
                    <ul role="list" className="divide-y divide-gray-100">
                        {customers.map((person) => (<li key={person.id} className="flex justify-between gap-x-6 py-5">
                            <div className="flex gap-x-4">
                                <img className="h-12 w-12 flex-none rounded-full bg-gray-50"
                                     src={"https://www.gravatar.com/avatar/" + md5(person.email)}
                                     alt=""/>
                                <div className="min-w-0 flex-auto">
                                    <p className="text-sm font-semibold leading-6 text-gray-900">{person.name}</p>
                                    <p className="mt-1 truncate text-xs leading-5 text-gray-500">{person.email}</p>
                                </div>
                            </div>
                            <div className=" sm:flex sm:flex-row sm:items-end">
                                <button
                                    onClick={() => handleDelete(person.id)}
                                    type="button"
                                    className="rounded-md bg-red-500 px-2 py-1 text-sm font-light text-white shadow-sm hover:bg-red-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-500"
                                >
                                    Delete
                                </button>
                            </div>
                        </li>))}
                    </ul>
                </div>

            </div>
        </div>

    );
}

export default App;
