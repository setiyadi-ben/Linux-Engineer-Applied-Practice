# Understanding REST and CRUD
## [**back to Linux-Engineer-Applied-Practice**](../README.md)
### [**back to Table of Contents**](../README.md)
### [**back to springTools**](/Java-Webapps-Simulation/Dev-Project/SpringTools4_Eclipse/springTools.md)

## What is CRUD?

**CRUD** stands for the basic actions you can do with data:

1. **Create**: Imagine you have a notebook, and you write a new piece of information in it. That's creating new data.
2. **Read**: You open the notebook and look at what you wrote. That’s reading the data.
3. **Update**: You decide to change what you wrote in the notebook, like correcting a mistake. That’s updating the data.
4. **Delete**: You erase something from the notebook. That’s deleting the data.

These are the four basic things you can do with your data.

## What is REST?

**REST** (Representational State Transfer) is a set of rules or guidelines for how different parts of a system communicate over the internet, usually when dealing with data. REST ensures that everyone (computers, apps, websites) understands the requests and responses being exchanged.

### Key Rules of REST

1. **Uniform Interface**: REST defines standard methods for interacting with data:
   - **GET**: To read data.
   - **POST**: To create new data.
   - **PUT**: To update existing data.
   - **DELETE**: To remove data.

2. **Stateless**: Each request in REST stands on its own, meaning that all the information needed for that request is included in it. The server doesn’t remember anything from previous requests, making the system easier to scale and manage.

3. **Client-Server**: REST separates the client (the one asking for data, like your web browser or app) from the server (the one holding the data). The client only needs to know how to ask for data using REST rules, and the server knows how to respond.

4. **Cacheable**: REST allows responses to be stored (cached) to improve efficiency. If data doesn’t change often, the server might send back a message saying, "You can just use what you already have" instead of sending the data again.

5. **Layered System**: REST works smoothly even if there are multiple layers of servers or systems involved. As long as the rules are followed, the system can handle requests effectively.

### Practical Example

When you use an app or visit a website, REST is often working in the background. For example:
- When you search for a book online (using a GET request), REST helps your device ask the server to send back information about that book.
- If you want to add a new book review (using a POST request), REST helps your device send that new review to the server.
- If you update your review (using a PUT request), REST guides your device on how to send the updated information.
- If you delete your review (using a DELETE request), REST ensures that your request to remove it is understood.

## Summary

- **CRUD** is about the basic actions (create, read, update, delete) you can perform on data.
- **REST** is the set of rules that guides how you ask for those actions to be done, and it can do more than just CRUD.
