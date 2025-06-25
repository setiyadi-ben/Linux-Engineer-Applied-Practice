public class MethodOverloading {
    public static void main(String[] args) {
        /*
         - Method overloading adalah kemampuan untuk membuat method dengan nama
            yang lebih dari sekali.
         - Ketentuannya parameter di method harus berbeda-beda, entah jumlah atau
            tipe datanya yang berbeda.
         - Jika ada yang sama, maka Java akan error
         */
        // Pemanggilan method pertama
        sayHello();
        // Pemanggilan method kedua
        sayHello("Eko");
        // Pemanggilan method ketiga
        sayHello("Eko", "Kurniawan");
        
    }

    // Method pertama tanpa menggunakan parameter
    static void sayHello(){
        System.out.println("Hello");
    }

    // Method kedua menggunakan 1 parameter string
    static void sayHello(String name){
        System.out.println("Hello "+ name);
    }

    // Method ketiga menggunakan 2 parameter string
    static void sayHello(String firstName, String lastName){
        System.out.println("Hello "+ firstName +" "+lastName);
    }
}
