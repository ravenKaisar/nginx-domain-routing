import mysql from "mysql2/promise";
import { mysqlConfig } from "./config.js";

const getCustomersList = async () => {
    const query = `SELECT * FROM customers`;
    const connection = await mysql.createConnection(mysqlConfig);
    return connection.execute(query);
};

const getCustomerInfoById = async (id) => {
    const query = `SELECT * FROM customers where id = ${id}`;
    const connection = await mysql.createConnection(mysqlConfig);
    return connection.execute(query);
};
const createCustomer = async (params) => {
    const data = JSON.parse(params)
    const query = `INSERT INTO customers (name, email) VALUES ('${data.name}', '${data.email}')`;
    const connection = await mysql.createConnection(mysqlConfig);
    return connection.execute(query);
};

const deleteCustomerById = async (id) => {
    const query = `DELETE FROM customers where id = ${id}`;
    const connection = await mysql.createConnection(mysqlConfig);
    return connection.execute(query);
};


export { getCustomersList, getCustomerInfoById, createCustomer, deleteCustomerById };