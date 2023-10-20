import {useState} from "react";
import axios from "axios";
import {toast} from "react-toastify";

function Form({handleSubmission}) {
    const baseURL = "http://localhost:6006/api/v1/customers";
    const [isLoading, setIsLoading] = useState(false);

    const [form, setForm] = useState({
        name: '', email: '',
    });
    const handleChange = event => {
        setForm({
            ...form, [event.target.id]: event.target.value,
        });
    };

    const handleSubmit = event => {
        event.preventDefault();
        setIsLoading(true)
        axios.post(baseURL,
            {name: form.name, email: form.email},
            {headers: {"Content-Type": "application/json", "Accept": "application/json"}})
            .then((response) => {
                setIsLoading(false)
                setForm({name: '', email: ''})
                toast(`Successfully create a customer. Please reload this page`, {type: "success"})
            })
            .catch((error) => {
                setIsLoading(false)
                toast(`Something went qrong`, {type: "error"})
            })
        // handleSubmission();
    };
    return (<form onSubmit={handleSubmit}>
            <div className="space-y-12">
                <div className="border-b border-gray-900/10 pb-3">
                    <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                        <div className="sm:col-span-3">
                            <label htmlFor="name"
                                   className="block text-sm font-medium leading-6 text-gray-900">
                                Full Name
                            </label>
                            <div className="mt-2">
                                <input
                                    type="text"
                                    required="required"
                                    name="name"
                                    id="name"
                                    value={form.name}
                                    onChange={handleChange}
                                    autoComplete="given-name"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                />
                            </div>
                        </div>

                        <div className="sm:col-span-3">
                            <label htmlFor="email"
                                   className="block text-sm font-medium leading-6 text-gray-900">
                                Email Address
                            </label>
                            <div className="mt-2">
                                <input
                                    type="email"
                                    required="required"
                                    name="email"
                                    id="email"
                                    value={form.email}
                                    onChange={handleChange}
                                    autoComplete="email"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="mt-3 flex items-center justify-end gap-x-6">
                <button
                    type="submit"
                    className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                    {isLoading ? 'Saving' : 'Save'}
                </button>
            </div>
        </form>

    )
}

export default Form