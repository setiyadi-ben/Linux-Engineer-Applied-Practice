# Preparing the Environment for Coding in Java
## [**back to Linux-Engineer-Applied-Practice**](../README.md)
### [**back to Table of Contents**](../README.md)

## Basic Structure of a Java Program

### 1. Class Declaration
- **Why**: The class is the fundamental building block in Java. Everything in Java is part of a class, which is a blueprint for objects.
- **Convention**: Use PascalCase (capitalize the first letter of each word) for class names.
- **Reason**: This makes class names easily distinguishable from variables and methods, which improves readability.

```java
public class MyClass {
    // Class body
}
```

### 2. Main Method
- **Why**: The `main` method is the entry point of any Java application. It's where the program starts executing.
- **Convention**: Must be written exactly as `public static void main(String[] args)`.
- **Reason**: The Java Virtual Machine (JVM) looks for this specific method signature to start the program.

```java
public class MyClass {
    public static void main(String[] args) {
        // Main method body
    }
}
```

### 3. Statements
- **Why**: Statements are the instructions that the program executes.
- **Convention**: End each statement with a semicolon (`;`).
- **Reason**: Semicolons act as terminators to separate each statement, making it clear where one statement ends and the next begins.

```java
public class MyClass {
    public static void main(String[] args) {
        System.out.println("Hello, World!"); // This prints text to the console
    }
}
```

## Components of a Java Program

### 1. Comments
- **Why**: Comments are used to explain the code, making it easier to understand for anyone reading it later.
- **Convention**: Use `//` for single-line comments and `/* */` for multi-line comments.
- **Reason**: Helps in documenting the code and can be ignored by the compiler, ensuring they don’t affect the program.

```java
// This is a single-line comment

/*
This is a
multi-line comment
*/
```

### 2. Variables
- **Why**: Variables store data that your program can use and manipulate.
- **Convention**: Use camelCase (start with a lowercase letter and capitalize the first letter of subsequent words) for variable names.
- **Reason**: Distinguishes variable names from class names and improves readability.

```java
public class MyClass {
    public static void main(String[] args) {
        int myNumber = 5; // Declare an integer variable
        String myText = "Hello"; // Declare a string variable
    }
}
```

### 3. Methods
- **Why**: Methods are blocks of code that perform specific tasks and can be called upon as needed.
- **Convention**: Use camelCase for method names.
- **Reason**: Follows the standard naming convention that differentiates methods from classes, improving code readability and consistency.

```java
public class MyClass {
    public static void main(String[] args) {
        greet(); // Call the greet method
    }

    public static void greet() {
        System.out.println("Hello, World!");
    }
}
```

## Putting It All Together

Here's a complete simple Java program that includes all these elements with reasons:

```java
// This is a simple Java program
public class MyClass { // Class name in PascalCase
    public static void main(String[] args) { // Entry point
        int myNumber = 5; // camelCase variable
        String myText = "Hello, World!"; // camelCase variable
        
        // Print the values of the variables
        System.out.println(myNumber);
        System.out.println(myText);
        
        greet(); // Call the greet method
    }

    // Define a method called greet
    public static void greet() { // camelCase method
        System.out.println("Welcome to Java programming!");
    }
}
```

## Summary
- **Class**: Use PascalCase for easy identification.
- **Main Method**: Standard entry point for the program.
- **Statements**: End with semicolons for clarity.
- **Comments**: Explain code without affecting functionality.
- **Variables**: Use camelCase to distinguish from class names.
- **Methods**: Use camelCase for consistency and readability.

Understanding the reasons behind these conventions helps in writing clean, readable, and maintainable code.