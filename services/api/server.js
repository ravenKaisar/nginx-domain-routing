"use strict";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import { getCustomerInfoById, getCustomersList, createCustomer, deleteCustomerById } from "./services/mysql.js";


dotenv.config();
// environment variables
const expressPort = process.env.PORT || 8000;

//express
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// express endpoints
app.get("/", (_, res) => res.status(200).json({ message: 'success', }));

app.get("/api/v1/customers", async (req, res) => {
    try {
        const [data] = await getCustomersList();

        res.status(200).json({ message: "Success", "data": data });
    } catch (error) {
        res.status(500).json({ message: "Error", error });
    }
});

app.post("/api/v1/customers", async (req, res) => {
    const body = req.body;
    try {
        await createCustomer(JSON.stringify(body));
        res.status(200).json({ message: "Success" });
    } catch (error) {
        res.status(500).json({ message: "Error", error });
    }
});

app.get("/api/v1/customers/:id", async (req, res) => {
    const id = req.params.id;
    try {
        const [data] = await getCustomerInfoById(id);
        if (data.length == 0) {
            res.status(404).json({ message: "Resource not found" });
        }
        res.status(200).json({ message: "Success", data: data[0] });
    } catch (error) {
        res.status(500).json({ message: "Error", error });
    }
});
app.delete("/api/v1/customers/:id", async (req, res) => {
    const id = req.params.id;
    try {
        const [data] = await getCustomerInfoById(id);
        if (data.length == 0) {
            res.status(404).json({ message: "Resource not found" });
        }
        await deleteCustomerById(id);
        res.status(204).json({ message: "Success" });
    } catch (error) {
        res.status(500).json({ message: "Error", error });
    }
});

app.listen(expressPort, () => console.log(`served on port ${expressPort}`));
