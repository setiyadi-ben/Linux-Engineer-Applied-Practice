# HTTP Methods Overview

This document provides a brief overview of 8 commonly used HTTP methods along with use cases.

## 1. GET
- **Purpose:** Retrieve data from the server.
- **Example Use Case:** Loading a webpage or fetching a list of products from an API.
- **Example URL:** `GET /products`

### Data Flow:
Client requests data → Server responds with the data.

---

## 2. POST
- **Purpose:** Send data to the server to create a new resource.
- **Example Use Case:** Submitting a form to create a new user account.
- **Example URL:** `POST /users`

### Data Flow:
Client sends new data → Server processes and creates a resource.

---

## 3. PUT
- **Purpose:** Update an existing resource by sending new data.
- **Example Use Case:** Updating a user's profile information.
- **Example URL:** `PUT /users/123`

### Data Flow:
Client sends new data → Server updates the existing resource.

---

## 4. PATCH
- **Purpose:** Partially update an existing resource.
- **Example Use Case:** Changing only the email of a user's profile.
- **Example URL:** `PATCH /users/123`

### Data Flow:
Client sends a partial update → Server modifies the resource.

---

## 5. DELETE
- **Purpose:** Remove a resource from the server.
- **Example Use Case:** Deleting a user account.
- **Example URL:** `DELETE /users/123`

### Data Flow:
Client requests to delete → Server removes the resource.

---

## 6. HEAD
- **Purpose:** Retrieve headers of a resource without the body (content).
- **Example Use Case:** Checking if a webpage exists without downloading its content.
- **Example URL:** `HEAD /products`

### Data Flow:
Client requests headers → Server responds with headers only.

---

## 7. OPTIONS
- **Purpose:** Determine which HTTP methods are supported by the server.
- **Example Use Case:** Check if `PUT` or `DELETE` is allowed on a resource.
- **Example URL:** `OPTIONS /products`

### Data Flow:
Client asks for allowed methods → Server responds with supported methods.

---

## 8. TRACE
- **Purpose:** Echo the received request, useful for debugging.
- **Example Use Case:** Debugging request headers to see how data is modified between client and server.
- **Example URL:** `TRACE /products`

### Data Flow:
Client sends TRACE request → Server sends back what it received.
