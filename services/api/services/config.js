import dotenv from "dotenv";

dotenv.config();
const mysqlConfig = {
    host: process.env.MYSQL_HOST || "",
    user: process.env.MYSQL_USERNAME || "",
    password: process.env.MYSQL_PASSWORD || "",
    database: process.env.MYSQL_DATABASE || "",
    port: process.env.MYSQL_PORT || ""
}

export { mysqlConfig };