# HTTP Methods Overview
## [**back to Linux-Engineer-Applied-Practice**](../README.md)
### [**back to Table of Contents**](/Additional-Notes/Table-of-Contents.md)


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

# Idempotent and Non-Idempotent HTTP Methods

This document explains which HTTP methods are idempotent and non-idempotent, along with reasoning.

## Idempotent HTTP Methods

1. **GET**
   - **Why:** Repeated GET requests retrieve the same resource without changing anything on the server.
   - **Example:** Fetching a list of users multiple times doesn't modify the list.

2. **PUT**
   - **Why:** Sending the same data to update a resource multiple times has the same result each time.
   - **Example:** Updating a user's profile with the same data repeatedly leaves the profile unchanged after the first update.

3. **DELETE**
   - **Why:** Although it removes a resource, sending the DELETE request repeatedly results in the same outcome: the resource remains deleted.
   - **Example:** Deleting a user twice doesn't have a different result after the first deletion.

4. **HEAD**
   - **Why:** Like GET, it only retrieves the headers of a resource without affecting the server state. Repeating the request doesn't change anything.
   - **Example:** Fetching headers from a product page multiple times.

5. **OPTIONS**
   - **Why:** This method only checks the available HTTP methods for a resource without altering the resource.
   - **Example:** Asking the server which methods are allowed on a resource will always return the same information.

---

## Non-Idempotent HTTP Methods

1. **POST**
   - **Why:** POST creates a new resource, and sending it multiple times can result in multiple resources being created.
   - **Example:** Submitting the same form twice might create two separate records.

2. **PATCH**
   - **Why:** PATCH partially updates a resource, and the outcome can vary with each request, depending on what is updated.
   - **Example:** Modifying only one field of a user's profile could have different effects when applied multiple times, making it non-idempotent.

---

## Summary of Idempotency

- **Idempotent methods** ensure that repeating the same request produces the same result as if it were done once. This makes them safe for retries, especially in case of network issues.
- **Non-Idempotent methods** can have different outcomes when repeated, potentially leading to multiple creations or unpredictable updates.

